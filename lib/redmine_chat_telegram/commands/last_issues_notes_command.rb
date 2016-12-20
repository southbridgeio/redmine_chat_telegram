module RedmineChatTelegram
  module Commands
    class LastIssuesNotesCommand < BaseBotCommand
      def execute
        return unless account.present?
        send_message(message_text)
      end

      private

      def visible_project_ids
        Project.where(Project.visible_condition(account.user)).pluck(:id)
      end

      def issues
        @issues ||= Issue.open
                  .where(project_id: visible_project_ids)
                  .order(updated_on: :desc).limit(5)
      end

      def last_issue_journal(issue)
        last_journal = issue.journals.where.not(notes: '').last
        if last_journal.present?
          time = I18n.l(last_journal.created_on, format: :long)
          "<pre>#{ActionController::Base.helpers.strip_tags last_journal.notes[0, 500]}</pre> <i>#{time}</i>"
        else
          "<pre>#{I18n.t('redmine_chat_telegram.bot.without_comments')}</pre>"
        end
      end

      def message_text
        issues.inject('') do |message, issue|
          url = issue_url(issue)
          journal = last_issue_journal(issue)
          message << %(<a href="#{url}">##{issue.id}</a>: #{issue.subject} #{journal}\n\n)
        end
      end
    end
  end
end
