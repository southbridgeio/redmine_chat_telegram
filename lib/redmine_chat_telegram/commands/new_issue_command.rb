module RedmineChatTelegram
  module Commands
    class NewIssueCommand < BaseBotCommand
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
        bot.send_message(
          chat_id: command.chat.id,
          text: I18n.t('redmine_chat_telegram.bot.new_issue.choice_project'),
          reply_markup: projects_list_markup)
      end

      def execute_step_2
        project_name = command.text
        users = Project
                .where(Project.visible_condition(account.user))
                .find_by(name: project_name)
                .try(:assignable_users)
        if users.present? && users.count > 0
          executing_command.update(step_number: 3, data: { project_name: project_name })
          bot.send_message(
            chat_id: command.chat.id,
            text: I18n.t('redmine_chat_telegram.bot.new_issue.choice_user'),
            reply_markup: users_list_markup(users))
        else
          bot.send_message(chat_id: command.chat.id, text: I18n.t('redmine_chat_telegram.bot.new_issue.user_not_found'))
        end
      end

      def execute_step_3
        firstname, lastname = command.text.split(' ')

        executing_command.update(
          step_number: 4,
          data: executing_command.data.merge(user: { firstname: firstname, lastname: lastname }))

        bot.send_message(chat_id: command.chat.id, text: I18n.t('redmine_chat_telegram.bot.new_issue.input_subject'))
      end

      def execute_step_4
        executing_command.update(
          step_number: 5,
          data: executing_command.data.merge(subject: command.text))

        bot.send_message(chat_id: command.chat.id, text: I18n.t('redmine_chat_telegram.bot.new_issue.input_text'))
      end

      def execute_step_5
        project = Project.find_by(name: executing_command.data[:project_name])
        assigned_to = User.find_by(firstname: executing_command.data[:user][:firstname],
                                   lastname: executing_command.data[:user][:lastname])
        subject = executing_command.data[:subject]
        text = command.text

        begin
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

          executing_command.destroy

          issue_url = issue_url(issue)
          message_text = I18n.t('redmine_chat_telegram.bot.new_issue.success') +
                         " [##{issue.id}](#{issue_url})"
          bot.send_message(
            chat_id: command.chat.id,
            text: message_text,
            parse_mode: 'Markdown',
            reply_markup: Telegrammer::DataTypes::ReplyKeyboardHide.new(hide_keyboard: true))
        rescue
          bot.send_message(chat_id: command.chat.id, text: I18n.t('redmine_chat_telegram.bot.new_issue.error'))
        end
      end

      def projects_list_markup
        project_names = Project.where(Project.visible_condition(account.user)).sorted.pluck(:name)
        Telegrammer::DataTypes::ReplyKeyboardMarkup.new(
          keyboard: project_names.each_slice(2).to_a,
          one_time_keyboard: true,
          resize_keyboard: true)
      end

      def users_list_markup(users)
        user_names = users.map do |user|
          "#{user.firstname} #{user.lastname}"
        end

        Telegrammer::DataTypes::ReplyKeyboardMarkup.new(
          keyboard: user_names.each_slice(2).to_a,
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
        @executing_command ||= RedmineChatTelegram::ExecutingCommand.create(name: 'new',
                                                                            account: account)
      end
    end
  end
end
