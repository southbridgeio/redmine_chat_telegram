module RedmineChatTelegram
  module Commands
    class FindIssuesCommand < BaseBotCommand

      MESSAGES = {
        'hot' => "*Назначенные вам задачи с активностью за последние сутки:*\n",
        'me'  => "*Назначенные вам задачи:*\n"
      }

      def execute
        if issues.count > 0
          bot.send_message(chat_id: command.chat.id, text: issues_list, parse_mode: 'Markdown')
        else
          bot.send_message(chat_id: command.chat.id, text: "Не найдено задач.")
        end
      end

      private

      def command_name
        @command_name ||= command.text.match(/^\/(\w+)/)[1]
      end

      def message
        @message ||= MESSAGES[command_name]
      end

      def issues
        @issues ||= issue_filters[command_name]
      end

      def issue_filters
        {
          'me'  => Issue.open.where(assigned_to: account.user),
          'hot' => Issue.open
                  .where(assigned_to: account.user)
                  .where('updated_on >= ?', 24.hours.ago),
        }
      end

      def issues_list
        issues.inject(message) do |issues_list, issue|
          url = Rails.application.routes.url_helpers.issue_url(issue, host: Setting.host_name)
          issues_list << "#{ issue.subject }: #{ url }\n"
        end
      end
    end
  end
end
