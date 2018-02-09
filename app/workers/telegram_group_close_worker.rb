class TelegramGroupCloseWorker
  include Sidekiq::Worker
  include TelegramCommon::Tdlib::DependencyProviders::GetChatLink
  include TelegramCommon::Tdlib::DependencyProviders::CloseChat

  def perform(telegram_id, user_id = nil)
    RedmineChatTelegram.set_locale

    find_user(user_id)

    return if telegram_id.nil?

    store_chat_name(telegram_id)

    reset_chat_link # Old link will not work after it.

    send_chat_notification(telegram_id)

    remove_users_from_chat
  end

  private

  attr_reader :user, :chat_id

  def find_user(user_id)
    @user = User.find_by(id: user_id) || User.anonymous
    logger.debug user.inspect
  end

  def store_chat_name(telegram_id)
    @chat_id = telegram_id.abs
  end

  def reset_chat_link
    get_chat_link.(chat_id)
  end

  def send_chat_notification(telegram_id)
    TelegramMessageSenderWorker.perform_async(telegram_id, close_message_text)
  end

  def close_message_text
    user.anonymous? ?
      I18n.t('redmine_chat_telegram.messages.closed_automaticaly') :
      I18n.t('redmine_chat_telegram.messages.closed_from_issue')
  end

  def remove_users_from_chat
    close_chat.(chat_id)
  end

  def logger
    @logger ||= Logger.new(Rails.root.join('log/chat_telegram', 'telegram-group-close.log'))
  end
end
