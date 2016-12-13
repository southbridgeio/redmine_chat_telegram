class TelegramGroupCloseWorker
  include Sidekiq::Worker
  TELEGRAM_GROUP_CLOSE_LOG = Logger.new(Rails.root.join('log/chat_telegram', 'telegram-group-close.log'))

  def perform(telegram_id, user_id = nil)
    I18n.locale = Setting['default_language']

    user = user_id.present? ? User.find(user_id) : User.anonymous

    TELEGRAM_GROUP_CLOSE_LOG.debug user.inspect

    chat_name = "chat##{telegram_id.abs}"

    TELEGRAM_GROUP_CLOSE_LOG.debug chat_name

    # Reset chat link. Old link will not work after it.
    cmd = "export_chat_link #{chat_name}"
    RedmineChatTelegram.socket_cli_command(cmd, TELEGRAM_GROUP_CLOSE_LOG)

    # send notification to chat
    close_message_text = user.anonymous? ?
        I18n.t('redmine_chat_telegram.messages.closed_automaticaly') :
        I18n.t('redmine_chat_telegram.messages.closed_from_issue')

    TelegramMessageSenderWorker.perform_async(telegram_id, close_message_text)

    # remove chat users

    cmd  = "chat_info #{chat_name}"
    json = RedmineChatTelegram.socket_cli_command(cmd, TELEGRAM_GROUP_CLOSE_LOG)

    admin   = json['admin']
    members = json['members']

    if members.present?
      members_without_admin = members.select { |member| member['id'] != admin['id'] }

      members_without_admin.each do |member|
        telegram_user_id = "user##{member['id']}"
        cmd              = "chat_del_user #{chat_name} #{telegram_user_id}"
        RedmineChatTelegram.socket_cli_command(cmd, TELEGRAM_GROUP_CLOSE_LOG)
      end

      telegram_user_id = "user##{admin['id']}"
      cmd              = "chat_del_user #{chat_name} #{telegram_user_id}"
      RedmineChatTelegram.socket_cli_command(cmd, TELEGRAM_GROUP_CLOSE_LOG)
    end

  rescue ActiveRecord::RecordNotFound => e
    # ignore
  end
end
