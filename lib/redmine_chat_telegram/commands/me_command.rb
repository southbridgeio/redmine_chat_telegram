module RedmineChatTelegram
  module Commands
    class MeCommand < BaseBotCommand

      def execute
        if issues.count > 0
          bot.send_message(chat_id: command.chat.id, text: issues_list, parse_mode: 'Markdown')
        else
          bot.send_message(chat_id: command.chat.id, text: "Не найдено задач.")
        end
      end

      private

      def issues
        @issues ||= Issue.open.where(assigned_to: account.user)
      end

      def issues_list
        message = "*Назначенные вам задачи:*\n"
        issues.inject(message) do |issues_list, issue|
          url = Rails.application.routes.url_helpers.issue_url(issue, host: Setting.host_name)
          issues_list << "#{ issue.subject }: #{ url }\n"
        end
      end
    end
  end
end
