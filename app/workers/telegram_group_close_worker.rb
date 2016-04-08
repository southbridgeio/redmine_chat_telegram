class TelegramGroupCloseWorker
  include Sidekiq::Worker
  TELEGRAM_GROUP_CLOSE_LOG = Logger.new(Rails.root.join('log/chat_telegram', 'telegram-group-close.log'))

  def perform(telegram_id, user_id = nil)
    I18n.locale = Setting['default_language']

    user = user_id.present? ? User.find(user_id) : User.anonymous

    TELEGRAM_GROUP_CLOSE_LOG.debug user.inspect

    cli_base = RedmineChatTelegram.cli_base

    chat_name = "chat##{telegram_id.abs}"

    TELEGRAM_GROUP_CLOSE_LOG.debug chat_name

    # Reset chat link. Old link will not work after it.
    cmd = "#{cli_base} \"export_chat_link #{chat_name}\""
    RedmineChatTelegram.run_command_with_logging(cmd, TELEGRAM_GROUP_CLOSE_LOG)


    # send notification to chat
    close_message_text = user.anonymous? ?
        I18n.t('redmine_chat_telegram.messages.closed_automaticaly') :
        I18n.t('redmine_chat_telegram.messages.closed_from_issue')

    cmd       = "#{cli_base} \"msg #{chat_name} #{close_message_text}\""
    RedmineChatTelegram.run_command_with_logging(cmd, TELEGRAM_GROUP_CLOSE_LOG)

    # remove chat users

    cmd       = "#{cli_base} \"chat_info #{chat_name}\""
    chat_info = %x( #{cmd} )

    users_array = chat_info.scan(/user#\d+/)
    users       = users_array.group_by { |u| u }.sort_by { |u| u.last.size }.map(&:first) # remove self in last order
    users.each do |telegram_user_id|
      cmd = "#{cli_base} \"chat_del_user #{chat_name} #{telegram_user_id}\""
      RedmineChatTelegram.run_command_with_logging(cmd, TELEGRAM_GROUP_CLOSE_LOG)
    end

  rescue ActiveRecord::RecordNotFound => e
    # ignore
  end
end
