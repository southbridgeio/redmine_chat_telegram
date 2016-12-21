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
        send_message("Введите id задачи.")
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
          send_message("Выберите какой параметр изменить.", reply_markup: keyboard)
        else
          send_message("Задача с введенным id не найдена.")
        end
      end

      def execute_step_3
        executing_command.update(
          step_number: 4,
          data: executing_command.data.merge({ attribute_name: command.text }))
        send_message("Введите значение.")
      end

      def execute_step_4
        issue = Issue.find_by_id(executing_command.data[:issue_id])
        user = account.user
        attr = executing_command.data[:attribute_name]
        value = command.text
        journal = IssueUpdater.new(issue, user).call(attr => value)
        if journal.present? && journal.details.any?
          executing_command.destroy
          send_message(details_to_strings(journal.details).join("\n"))
        else
          send_message(I18n.t('redmine_chat_telegram.bot.error_editing_issue'))
        end
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
