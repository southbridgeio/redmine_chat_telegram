module RedmineChatTelegram
  module Commands
    class NewIssueCommand < BaseBotCommand
      PROJECTS_PER_PAGE = 10

      def execute
        return unless account.present?
        execute_step
      end

      private

      def execute_step
        send("execute_step_#{executing_command.step_number}")
      end

      def execute_step_1
        executing_command.update(step_number: 2)
        send_projects
      end

      def execute_step_2
        return send_projects if next_page?
        project_name = command.text
        assignables = Project
                        .where(Project.visible_condition(account.user))
                        .find_by(name: project_name)
                        .try(:assignable_users)
        if assignables.present? && assignables.count > 0
          executing_command.update(step_number: 3,
                                   data: executing_command.data.merge(project_name: project_name))
          send_message(I18n.t('redmine_chat_telegram.bot.new_issue.choice_user'),
                       reply_markup: assignable_list_markup(assignables))
        else
          executing_command.destroy
          send_message(
            I18n.t('redmine_chat_telegram.bot.new_issue.user_not_found'),
            reply_markup: Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true))
        end
      end

      def execute_step_3
        save_assignable
        send_message(I18n.t('redmine_chat_telegram.bot.new_issue.input_subject'))
      end

      def execute_step_4
        executing_command.update(
          step_number: 5,
          data: executing_command.data.merge(subject: command.text))

        send_message(I18n.t('redmine_chat_telegram.bot.new_issue.input_text'))
      end

      def execute_step_5
        issue = create_issue

        executing_command.update(step_number: 6, data: executing_command.data.merge(issue_id: issue.id))

        issue_url = issue_url(issue)
        message_text = I18n.t('redmine_chat_telegram.bot.new_issue.success') +
                       %( <a href="#{issue_url}">##{issue.id}</a>\n) +
                       I18n.t('redmine_chat_telegram.bot.new_issue.create_chat_question')

        keyboard = Telegram::Bot::Types::ReplyKeyboardMarkup.new(
          keyboard: [[I18n.t('redmine_chat_telegram.bot.new_issue.yes_answer'),
                      I18n.t('redmine_chat_telegram.bot.new_issue.no_answer')]],
          one_time_keyboard: true,
          resize_keyboard: true)

        send_message(message_text,
                     reply_markup: keyboard)
      rescue StandardError
        send_message(I18n.t('redmine_chat_telegram.bot.new_issue.error'))
      end

      def execute_step_6
        executing_command.destroy
        create_chat if command.text == I18n.t('redmine_chat_telegram.bot.new_issue.yes_answer')
      end

      def next_page?
        command.text == I18n.t('redmine_chat_telegram.bot.new_issue.next_page')
      end

      def create_chat
        issue_id = executing_command.data[:issue_id]
        issue = Issue.find(issue_id)

        send_message(
          I18n.t('redmine_chat_telegram.bot.creating_chat'),
          reply_markup: Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
        )

        RedmineChatTelegram::GroupChatCreator.new(issue, account.user).run

        issue.reload
        message_text = I18n.t('redmine_chat_telegram.journal.chat_was_created',
                              telegram_chat_url: issue.telegram_group.shared_url)

        send_message(message_text)
      end

      def create_issue
        project = Project.find_by(name: executing_command.data[:project_name])

        assigned_to = find_assignable
        subject = executing_command.data[:subject]
        text = command.text

        issue = Issue.new(
          author: account.user,
          project: project,
          assigned_to: assigned_to,
          subject: subject,
          description: text)
        issue.priority = IssuePriority.where(is_default: true).first || IssuePriority.first
        issue.tracker = issue.project.trackers.first
        issue.status = issue.new_statuses_allowed_to(account.user).first
        issue.save!
        issue
      end

      def send_projects
        projects = Project.where(Project.visible_condition(account.user))
        if projects.count > 0
          current_page = executing_command.data[:current_page]
          next_page = current_page + 1
          if projects.count <= PROJECTS_PER_PAGE
            message = I18n.t('redmine_chat_telegram.bot.new_issue.choice_project_without_page')
          else
            message = I18n.t('redmine_chat_telegram.bot.new_issue.choice_project_with_page',
                             page: current_page)
          end
          send_message(message, reply_markup: projects_list_markup(projects))
          executing_command.update(data: executing_command.data.merge(current_page: next_page))
        else
          send_message(I18n.t('redmine_chat_telegram.bot.new_issue.projects_not_found'))
        end
      end

      def projects_list_markup(all_projects)
        current_page = executing_command.data[:current_page]
        limit = PROJECTS_PER_PAGE
        offset = (current_page - 1) * limit
        projects = all_projects.sorted.limit(limit).offset(offset)
        project_names = projects.pluck(:name)

        if all_projects.count > limit && (offset + limit) < all_projects.count
          project_names << I18n.t('redmine_chat_telegram.bot.new_issue.next_page')
        end

        Telegram::Bot::Types::ReplyKeyboardMarkup.new(
          keyboard: project_names.each_slice(2).to_a,
          one_time_keyboard: true,
          resize_keyboard: true)
      end

      def assignable_list_markup(assignables)
        assignables_names = assignables.map do |assignable|
          if assignable.is_a? Group
            "#{assignable.name} (#{I18n.t(:label_group)})"
          else
            "#{assignable.firstname} #{assignable.lastname}"
          end
        end
        assignables_names.prepend I18n.t('redmine_chat_telegram.bot.new_issue.without_user')

        Telegram::Bot::Types::ReplyKeyboardMarkup.new(
          keyboard: assignables_names.each_slice(2).to_a,
          one_time_keyboard: true,
          resize_keyboard: true)
      end

      def executing_command
        @executing_command ||= RedmineChatTelegram::ExecutingCommand
                                 .joins(:account)
                                 .find_by!(
                                   name: 'new',
                                   telegram_common_accounts:
                                     { telegram_id: command.from.id })
      rescue ActiveRecord::RecordNotFound
        @executing_command ||= RedmineChatTelegram::ExecutingCommand.create(
          name: 'new',
          data: {current_page: 1},
          account: account)
      end

      def save_assignable
        if command.text == I18n.t('redmine_chat_telegram.bot.without_user')
          executing_command.update(
            step_number: 4,
            data: executing_command.data.merge(user: nil))
        elsif command.text =~ /\(#{I18n.t(:label_group)}\)/
          group_name = command.text.match(/^(.+) \(#{I18n.t(:label_group)}\)$/)[1]
          executing_command.update(
            step_number: 4,
            data: executing_command.data.merge(group: group_name))
        else
          firstname, lastname = command.text.split(' ')
          executing_command.update(
            step_number: 4,
            data: executing_command.data.merge(user: { firstname: firstname, lastname: lastname }))
        end
      end

      def find_assignable
        if executing_command.data[:user].present?
          User.find_by(firstname: executing_command.data[:user][:firstname],
                       lastname: executing_command.data[:user][:lastname])
        elsif executing_command.data[:group].present?
          Group.find_by(lastname: executing_command.data[:group])
        end
      end
    end
  end
end
