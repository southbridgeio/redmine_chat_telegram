class TelegramGroupCloseWorker
  include Sidekiq::Worker

  def perform(telegram_id, user_id = nil)
    RedmineChatTelegram.set_locale

    find_user(user_id)

    store_chat_name(telegram_id)

    reset_chat_link # Old link will not work after it.

    send_chat_notification(telegram_id)

    remove_users_from_chat
  end

  private

  attr_reader :user, :chat_name

  def find_user(user_id)
    @user = User.find_by(id: user_id) || User.anonymous
    logger.debug user.inspect
  end

  def store_chat_name(telegram_id)
    @chat_name = "chat##{telegram_id.abs}"
    logger.debug chat_name
  end

  def reset_chat_link
    cmd = "export_chat_link #{chat_name}"
    RedmineChatTelegram.socket_cli_command(cmd, logger)
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
    cmd = "chat_info #{chat_name}"
    json = RedmineChatTelegram.socket_cli_command(cmd, logger)

    admin = json['admin']
    members = json['members']

    return unless members.present?

    members_without_admin = members.select { |member| member['id'] != admin['id'] }

    members_without_admin.each do |member|
      telegram_user_id = "user##{member['id']}"
      cmd = "chat_del_user #{chat_name} #{telegram_user_id}"
      RedmineChatTelegram.socket_cli_command(cmd, logger)
    end

    telegram_user_id = "user##{admin['id']}"
    cmd = "chat_del_user #{chat_name} #{telegram_user_id}"
    RedmineChatTelegram.socket_cli_command(cmd, logger)
  end

  def logger
    @logger ||= Logger.new(Rails.root.join('log/chat_telegram', 'telegram-group-close.log'))
  end
end
