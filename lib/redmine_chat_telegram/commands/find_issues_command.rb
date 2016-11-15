module RedmineChatTelegram
  module Commands
    class FindIssuesCommand < BaseBotCommand
      LOGGER = Logger.new(Rails.root.join('log/chat_telegram', 'bot-command-find-issues.log'))

      def execute
        return unless account.present?
        if issues.count > 0
          logger.debug "FindIssuesCommand:\n#{command.inspect}\n\n#{issues_list}\n*******************"
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
        end
      end

      def message
        @message ||= I18n.t("redmine_chat_telegram.bot.#{command_name}")
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
        message_title = "*#{message}:*\n"
        issues.inject(message_title) do |message_text, issue|
          url = issue_url(issue)
          message_text << "[##{issue.id}](#{url}): #{issue.subject}\n"
        end
      end
    end
  end
end
