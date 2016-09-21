class TelegramIssueNotificationsWorker
  include Sidekiq::Worker
  include IssuesHelper

  TELEGRAM_ISSUE_NOTIFICATIONS_LOG =
    Logger.new(Rails.root.join('log/chat_telegram', 'telegram-issue-notifications.log'))

  def perform(telegram_id, journal_id)
    I18n.locale = Setting['default_language']

    journal = Journal.find(journal_id)

    message = "<b>#{journal.user.name}</b>"

    message << "\n#{details_to_strings(journal.visible_details, true).join("\n")}" if journal.details.present?

    message << "\n<pre>#{journal.notes}</pre>" if journal.notes.present?

    TelegramMessageSenderWorker.perform_async(telegram_id, message)
  rescue ActiveRecord::RecordNotFound => e
    # ignore
  end
end
