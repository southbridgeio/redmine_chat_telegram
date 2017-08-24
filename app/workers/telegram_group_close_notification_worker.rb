class TelegramGroupCloseNotificationWorker
  include Sidekiq::Worker
  include ActionView::Helpers::DateHelper
  include ApplicationHelper

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
                                time_in_words: time_in_words)

    TelegramMessageSenderWorker.perform_async(telegram_id, close_message_text)
  end

  def time_in_words
    (days_count > 0)? days_string : hours_string
  end

  def hours_string
    l_key = 'datetime.distance_in_words.x_hours'

    if current_language == :ru
      Pluralization.pluralize(hours_count,
                              l("#{l_key}.one",  count: hours_count),
                              l("#{l_key}.few",  count: hours_count),
                              l("#{l_key}.many", count: hours_count),
                              l("#{l_key}.other",count: hours_count))
    else
      Pluralization.en_pluralize(hours_count,
                                 l("#{l_key}.one"),
                                 l("#{l_key}.other", count: hours_count))
    end
  end

  def days_string
    l_key = 'datetime.distance_in_words.x_days'

    if current_language == :ru
      Pluralization.pluralize(days_count,
                              l("#{l_key}.one",  count: days_count),
                              l("#{l_key}.few",  count: days_count),
                              l("#{l_key}.many", count: days_count),
                              l("#{l_key}.other",count: days_count))
    else
      Pluralization.en_pluralize(days_count,
                              l("#{l_key}.one"),
                              l("#{l_key}.other", count: days_count))
    end
  end

  def hours_count
    time_diff = (Time.current - telegram_group.need_to_close_at)
    (time_diff / 1.hour).round.abs
  end

  def days_count
    telegram_group.need_to_close_at.to_date.mjd - Date.today.mjd
  end

  def telegram_group
    @telegram_group ||= issue.telegram_group
  end

  def logger
    @logger ||= Logger.new(Rails.root.join('log/chat_telegram',
                                           'telegram-group-close-notification.log'))
  end
end
