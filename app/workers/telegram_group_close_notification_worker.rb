class TelegramGroupCloseNotificationWorker
  include Sidekiq::Worker
  include ActionView::Helpers::DateHelper

  TELEGRAM_GROUP_CLOSE_NOTIFICATION_LOG = Logger.new(Rails.root.join('log/chat_telegram',
                                                                     'telegram-group-close-notification.log'))

  def perform(issue_id)
    I18n.locale = Setting['default_language']

    issue = Issue.find issue_id

    telegram_group = issue.telegram_group
    telegram_id = telegram_group.telegram_id.abs

    TELEGRAM_GROUP_CLOSE_NOTIFICATION_LOG.debug "chat##{telegram_id}"

    # send notification to chat
    time_in_words      = distance_of_time_in_words(Time.now, telegram_group.need_to_close_at)
    close_message_text = I18n.t('redmine_chat_telegram.messages.close_notification', time_in_words: time_in_words)

    TelegramMessageSenderWorker.perform_async(telegram_id, close_message_text)

    telegram_group.update last_notification_at: Time.now

  rescue ActiveRecord::RecordNotFound => e
    # ignore
  end
end
