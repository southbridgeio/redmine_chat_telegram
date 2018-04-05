module RedmineChatTelegram
  module Commands
    class EditIssueCommand < BaseBotCommand
      include IssuesHelper
      include ActionView::Helpers::TagHelper
      include ERB::Util
      include TelegramCommon::Tdlib::DependencyProviders::RenameChat
      include TelegramCommon::Tdlib::DependencyProviders::GetChat

      PER_PAGE = 10

      EDITABLES = [
        'project',
        'tracker',
        'subject',
        'status',
        'priority',
        'assigned_to',
        'start_date',
        'due_date',
        'estimated_hours',
        'done_ratio']

      def execute
        return unless account.present?
        execute_step
      end

      private

      def execute_step
        send("execute_step_#{executing_command.step_number}")
      end

      def execute_step_1
        issue_id = command.text.match(/\/\w+ #?(\d+)/).try(:[], 1)
        project_name = command_arguments
        if command_arguments == "hot"
          executing_command.update(step_number: 3)
          send_hot_issues
        elsif command_arguments == "project"
          executing_command.update(step_number: 2)
          send_allowed_projects
        elsif issue_id.present?
          execute_step_3
        elsif project_name.present?
          execute_step_2
        else
          send_message(locale('help'))
          executing_command.destroy
        end
      end

      def execute_step_2
        return send_allowed_projects if next_page?
        project_name = command.text.match(/\/\w+ (.+)/).try(:[], 1)
        project_name = command.text unless project_name.present?

        project = Project.where(Project.visible_condition(account.user)).like(project_name).first
        if project.present?
          executing_command.update(step_number: 3, data: executing_command.data.merge(project_id: project.id))
          send_all_issues_for_project(project)
        else
          finish_with_error
        end
      end

      def execute_step_3
        issue_id = command.text.gsub('/issue', '').gsub('/task', '').match(/#?(\d+)/).try(:[], 1)
        issue = Issue.find_by_id(issue_id)
        if issue.present?
          EDITABLES << 'subject_chat' if issue.telegram_group.present?
          executing_command.update(step_number: 4, data: executing_command.data.merge(issue_id: issue.id))
          send_message(locale('select_param', true), reply_markup: make_keyboard(EDITABLES))
        else
          finish_with_error
        end
      end

      def execute_step_4
        return finish_with_error unless EDITABLES.include? command.text
        executing_command.update(
          step_number: 5,
          data: executing_command.data.merge({ attribute_name: command.text }))

        case command.text
        when 'project'
          send_projects
        when 'tracker'
          send_trackers
        when 'priority'
          send_priorities
        when 'status'
          send_statuses
        when 'assigned_to'
          send_users
        else
          send_message(locale('input_value'))
        end
      end

      def execute_step_5
        user = account.user
        attr = executing_command.data[:attribute_name]
        value = command.text
        return change_issue_chat_name(value) if attr == 'subject_chat'
        journal = IssueUpdater.new(issue, user).call(attr => value)
        executing_command.destroy
        if journal.present?
          if journal.details.any?
            send_message(details_to_strings(journal.details).join("\n"))
          else
            send_message(I18n.t('redmine_chat_telegram.bot.warning_editing_issue', field: attr))
          end
        else
          send_message(I18n.t('redmine_chat_telegram.bot.error_editing_issue'))
        end
      end

      def send_hot_issues
        title = "<b>#{I18n.t('redmine_chat_telegram.bot.hot')}:</b>\n"
        issues = Issue.joins(:project).open
                      .where(projects: { status: 1 })
                      .where(assigned_to: account.user)
                      .where('issues.updated_on >= ?', 24.hours.ago)
                      .limit(10)
        send_issues(issues, title)
      end

      def send_all_issues_for_project(project)
        title = "<b>#{I18n.t('redmine_chat_telegram.bot.edit_issue.project_issues')}:</b>\n"
        send_issues(project.issues.limit(10), title)
      end

      def send_issues(issues, title)
        message_text = title
        issues.each do |issue|
          url = issue_url(issue)
          message_text << %(<a href="#{url}">##{issue.id}</a>: #{issue.subject}\n)
        end
        send_message(message_text)
        send_message(locale('input_id', true), reply_markup: make_keyboard(issues.pluck(:id).map(&:to_s)))
      end

      def next_page?
        command.text == I18n.t('redmine_chat_telegram.bot.new_issue.next_page')
      end

      def send_allowed_projects
        projects = Project.where(Project.visible_condition(account.user))
        if projects.count > 0
          current_page = executing_command.data[:current_page]
          next_page = current_page + 1
          if projects.count <= PER_PAGE
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
        limit = PER_PAGE
        offset = (current_page - 1) * limit
        projects = all_projects.sorted.limit(limit).offset(offset)
        project_names = projects.pluck(:name)

        if all_projects.count > limit && (offset + limit) < all_projects.count
          project_names << I18n.t('redmine_chat_telegram.bot.new_issue.next_page')
        end

        make_keyboard(project_names)
      end

      def send_projects
        projects = issue.allowed_target_projects.pluck(:name)
        keyboard = make_keyboard(projects)
        send_message(locale('select_project'), reply_markup: keyboard)
      end

      def send_trackers
        priorities = issue.project.trackers.pluck(:name)
        keyboard = make_keyboard(priorities)
        send_message(locale('select_tracker'), reply_markup: keyboard)
      end

      def send_statuses
        statuses = issue.new_statuses_allowed_to(account.user).map(&:name)
        keyboard = make_keyboard(statuses)
        send_message(locale('select_status'), reply_markup: keyboard)
      end

      def send_users
        users = issue.assignable_users.map(&:login)
        keyboard = make_keyboard(users)
        send_message(locale('select_user'), reply_markup: keyboard)
      end

      def send_priorities
        priorities = IssuePriority.active.pluck(:name)
        keyboard = make_keyboard(priorities)
        send_message(locale('select_priority'), reply_markup: keyboard)
      end

      def change_issue_chat_name(name)
        if issue.telegram_group.present? && issue.telegram_group.telegram_id.present?
          if name.present?
            if account.user.allowed_to?(:edit_issues, issue.project)
              rename_chat.(issue.telegram_group.telegram_id, name)
              executing_command.destroy
              send_message(locale('chat_name_changed'))
            else
              send_message(I18n.t('redmine_chat_telegram.bot.access_denied'))
            end
          else
            chat_info = get_chat.(issue.telegram_group.telegram_id)
            send_message(chat_info['title'].to_s)
          end
        else
          send_message(locale('chat_for_issue_not_exist'))
          finish_with_error
        end
      end

      def make_keyboard(items)
        items_with_cancel = items + ['/cancel']
        Telegram::Bot::Types::ReplyKeyboardMarkup.new(
          keyboard: items_with_cancel.each_slice(2).to_a,
          one_time_keyboard: true,
          resize_keyboard: true)
      end

      def issue
        @issue ||= Issue.find_by_id(executing_command.data[:issue_id])
      end

      def project
        @project ||= Project.where(Project.visible_condition(account.user))
                            .find_by_name(executing_command.data[:project_id])
      end

      def locale(key, show_cancel = false)
        message = I18n.t("redmine_chat_telegram.bot.edit_issue.#{key}")
        if show_cancel
          [message, I18n.t("redmine_chat_telegram.bot.edit_issue.cancel_hint")].join ' '
        else
          message
        end
      end

      def finish_with_error
        executing_command.destroy
        send_message(
          locale('incorrect_value'),
          reply_markup: Telegram::Bot::Types::ReplyKeyboardRemove.new(hide_keyboard: true))
      end

      def executing_command
        @executing_command ||= RedmineChatTelegram::ExecutingCommand
                             .joins(:account)
                             .find_by!(
                               name: 'issue',
                               telegram_common_accounts:
                                 { telegram_id: command.from.id })
      rescue ActiveRecord::RecordNotFound
        @executing_command ||= RedmineChatTelegram::ExecutingCommand.create(name: 'issue', account: account, data: {current_page: 1})
      end
    end
  end
end
