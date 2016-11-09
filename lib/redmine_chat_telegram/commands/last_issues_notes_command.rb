module RedmineChatTelegram
  module Commands
    class LastIssuesNotesCommand < BaseBotCommand

      def execute
        return unless account.present?
        bot.send_message(chat_id: command.chat.id, text: message_text, parse_mode: 'Markdown')
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
        last_journal = issue.journals.where.not(notes: "").last
        if last_journal.present?
          time = I18n.l(last_journal.created_on, format: :long)
          "```text #{ last_journal.notes }```_#{ time }_"
        else
          "```text #{ I18n.t('redmine_chat_telegram.bot.without_comments') }```"
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
