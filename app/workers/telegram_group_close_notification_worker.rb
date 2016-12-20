class TelegramGroupCloseNotificationWorker
  include Sidekiq::Worker
  include ActionView::Helpers::DateHelper

  def perform(issue_id)
    RedmineChatTelegram.set_locale

    @issue = Issue.find_by id: issue_id

    return unless issue.present?
    return unless telegram_group.present?

    if telegram_group.telegram_id.present?
      send_chat_notification
      telegram_group.update last_notification_at: Time.now
    else
      telegram_group.destroy
    end
  end

  private

  attr_reader :issue

  def send_chat_notification
    telegram_id = telegram_group.telegram_id

    logger.debug "chat##{telegram_id}"

    close_message_text = I18n.t('redmine_chat_telegram.messages.close_notification',
                                time_in_words: days_string)

    TelegramMessageSenderWorker.perform_async(telegram_id, close_message_text)
  end

  def days_string
    days_count = telegram_group.need_to_close_at.to_date.mjd - Date.today.mjd
    days_word = Pluralization.pluralize(days_count, 'день', 'дня', 'дней', 'дня')
    "#{days_count} #{days_word}"
  end

  def telegram_group
    @telegram_group ||= issue.telegram_group
  end

  def logger
    @logger ||= Logger.new(Rails.root.join('log/chat_telegram',
                                           'telegram-group-close-notification.log'))
  end
end
