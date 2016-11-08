module RedmineChatTelegram
  module Commands
    class FindIssuesCommand < BaseBotCommand

      def execute
        if issues.count > 0
          bot.send_message(chat_id: command.chat.id, text: issues_list, parse_mode: 'Markdown')
        else
          issues_not_found = I18n.t('redmine_chat_telegram.bot.issues_not_found')
          bot.send_message(chat_id: command.chat.id, text: issues_not_found)
        end
      end

      private

      def command_name
        case command.text
        when /\/hot/
          'hot'
        when /\/me/
          'me'
        when /\/deadline|\/dl/
          'deadline'
        else
          nil
        end
      end

      def message
        @message ||= I18n.t("redmine_chat_telegram.bot.#{ command_name }")
      end

      def issues
        @issues ||= issue_filters[command_name]
      end

      def issue_filters
        assigned_to_me = Issue.open.where(assigned_to: account.user)
        {
          'me' => assigned_to_me,
          'hot' => assigned_to_me.where('updated_on >= ?', 24.hours.ago),
          'deadline' => assigned_to_me.where('due_date < ?', Date.today)
        }
      end

      def issues_list
        message_title = "*#{ message }:*\n"
        issues.inject(message_title) do |message_text, issue|
          url = Rails.application.routes.url_helpers.issue_url(issue, host: Setting.host_name)
          message_text << "#{ url }: #{ issue.subject }\n"
        end
      end
    end
  end
end
