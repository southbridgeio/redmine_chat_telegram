class TelegramHandlerWorker
  include Sidekiq::Worker
  sidekiq_options queue: :telegram

  def perform(params)
    message = Telegram::Bot::Types::Update.new(params).message

    if message.present?
      RedmineChatTelegram::Bot.new(message).call if message.is_a?(Telegram::Bot::Types::Message)

      group = RedmineChatTelegram::TelegramGroup.find_by(telegram_id: message.chat.id.abs)

      if group.present?
        sent_at = Time.at message.date

        from = message.from
        from_id = from.id
        from_first_name = from.first_name
        from_last_name = from.last_name
        from_username = from.username

        message_text = message.text

        TelegramMessage.where(telegram_id: message.message_id)
            .first_or_create issue_id: group.issue.id,
                             sent_at: sent_at,
                             from_id: from_id,
                             from_first_name: from_first_name,
                             from_last_name: from_last_name,
                             from_username: from_username,
                             message: message_text
      end
    else
      logger.fatal "Can't find message: #{params.to_json}"
    end
  end

  def logger
    @logger ||= Logger.new(Rails.root.join('log/chat_telegram',
                                           'telegram-handler.log'))
  end
end
