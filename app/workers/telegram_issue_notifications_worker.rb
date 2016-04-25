class TelegramIssueNotificationsWorker
  include Sidekiq::Worker
  include IssuesHelper

  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::UrlHelper
  include ERB::Util
  delegate :link_to, :to => 'ActionController::Base.helpers'

  TELEGRAM_ISSUE_NOTIFICATIONS_LOG = Logger.new(Rails.root.join('log/chat_telegram', 'telegram-issue-notifications.log'))

  def perform(telegram_id, journal_id)
    ActionView::Base.send(:include, Rails.application.routes.url_helpers)
    I18n.locale = Setting['default_language']

    journal = Journal.find(journal_id)

    if journal.details.any?
      message = "#{ details_to_strings(journal.visible_details).join("\n") }"
      message << "\n" << "<pre>#{ journal.notes }</pre>" unless journal.notes.blank?
    else
      message = "<pre>#{ journal.notes }</pre>"
    end
    message.prepend("<b>#{journal.user.name}</b>\n")

    TelegramMessageSenderWorker.perform_async(telegram_id, message)
  rescue ActiveRecord::RecordNotFound => e
    # ignore
  end
end
