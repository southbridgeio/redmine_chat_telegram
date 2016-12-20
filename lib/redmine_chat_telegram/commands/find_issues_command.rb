module RedmineChatTelegram
  module Commands
    class FindIssuesCommand < BaseBotCommand
      LOGGER = Logger.new(Rails.root.join('log/chat_telegram', 'bot-command-find-issues.log'))

      def execute
        return unless account.present?
        if issues.count > 0
          send_message(issues_list)
        else
          issues_not_found = I18n.t('redmine_chat_telegram.bot.issues_not_found')
          send_message(issues_not_found)
        end
      end

      private

      def command_name
        case command.text
        when %r{/hot}
          'hot'
        when %r{/me}
          'me'
        when %r{/deadline|/dl}
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
        assigned_to_me = Issue.joins(:project).open
                         .where(projects: { status: 1 })
                         .where(assigned_to: account.user)
        {
          'me' => assigned_to_me,
          'hot' => assigned_to_me.where('issues.updated_on >= ?', 24.hours.ago),
          'deadline' => assigned_to_me.where('due_date < ?', Date.today)
        }
      end

      def issues_list
        message_title = "<b>#{message}:</b>\n"
        issues.inject(message_title) do |message_text, issue|
          url = issue_url(issue)
          message_text << %(<a href="#{url}">##{issue.id}</a>: #{issue.subject}\n)
        end
      end
    end
  end
end
