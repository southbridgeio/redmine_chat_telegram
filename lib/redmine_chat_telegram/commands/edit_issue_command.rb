module RedmineChatTelegram
  module Commands
    class EditIssueCommand < BaseBotCommand
      include IssuesHelper
      include ActionView::Helpers::TagHelper
      include ERB::Util

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
        send_message(locale('input_id'))
        executing_command.update(step_number: 2)
      end

      def execute_step_2
        issue = Issue.find_by_id(command.text)
        if issue.present?
          executing_command.update(step_number: 3, data: { issue_id: issue.id })
          keyboard = Telegrammer::DataTypes::ReplyKeyboardMarkup.new(
            keyboard: EDITABLES.each_slice(2).to_a,
            one_time_keyboard: true,
            resize_keyboard: true)
          send_message(locale('select_param'), reply_markup: keyboard)
        else
          finish_with_error
        end
      end

      def execute_step_3
        return finish_with_error unless EDITABLES.include? command.text
        executing_command.update(
          step_number: 4,
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

      def execute_step_4
        user = account.user
        attr = executing_command.data[:attribute_name]
        value = command.text
        journal = IssueUpdater.new(issue, user).call(attr => value)
        executing_command.destroy
        if journal.present? && journal.details.any?
          send_message(details_to_strings(journal.details).join("\n"))
        else
          send_message(I18n.t('redmine_chat_telegram.bot.error_editing_issue'))
        end
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

      def make_keyboard(items)
        Telegrammer::DataTypes::ReplyKeyboardMarkup.new(
          keyboard: items.each_slice(2).to_a,
          one_time_keyboard: true,
          resize_keyboard: true)
      end

      def issue
        @issue ||= Issue.find_by_id(executing_command.data[:issue_id])
      end

      def locale(key)
        I18n.t("redmine_chat_telegram.bot.edit_issue.#{key}")
      end

      def finish_with_error
        executing_command.destroy
        send_message(
          locale('incorrect_value'),
          reply_markup: Telegrammer::DataTypes::ReplyKeyboardHide.new(hide_keyboard: true))
      end

      def executing_command
        @executing_command ||= RedmineChatTelegram::ExecutingCommand
                             .joins(:account)
                             .find_by!(
                               name: 'issue',
                               telegram_common_accounts:
                                 { telegram_id: command.from.id })
      rescue ActiveRecord::RecordNotFound
        @executing_command ||= RedmineChatTelegram::ExecutingCommand.create(name: 'issue',
                                                                            account: account)
      end
    end
  end
end
