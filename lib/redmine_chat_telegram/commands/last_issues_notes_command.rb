module RedmineChatTelegram
  module Commands
    class LastIssuesNotesCommand < BaseBotCommand

      def execute
        bot.send_message(chat_id: command.chat.id, text: message_text, parse_mode: 'Markdown')
      end

      private

      def visible_project_ids
        Project.where(Project.visible_condition(account.user))
      end

      def issues
        @issues ||= Issue.open.where(project_id: visible_project_ids).order(:updated_on).last(5)
      end

      def last_issue_journal(issue)
        last_journal = issue.journals.where.not(notes: "").last
        if last_journal.present?
          "```text #{ last_journal.notes }```"
        else
          "```text Без комментариев```"
        end
      end

      def message_text
        issues.inject("") do |message, issue|
          url = Rails.application.routes.url_helpers.issue_url(issue, host: Setting.host_name)
          journal = last_issue_journal(issue)
          message << "[##{ issue.id }](#{ url }) #{ issue.subject } #{ journal }\n\n"
        end
      end
    end
  end
end
