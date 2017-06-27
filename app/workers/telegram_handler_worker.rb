class TelegramHandlerWorker
  include Sidekiq::Worker
  sidekiq_options queue: :telegram

  def perform(params)
    message = Telegram::Bot::Types::Update.new(params).message

    if message.present?
      logger.debug params.to_json
      RedmineChatTelegram.handle_message(message)
    else
      logger.fatal "Can't find message: #{params.to_json}"
    end
  end

  def logger
    @logger ||= Logger.new(Rails.root.join('log/chat_telegram',
                                           'telegram-handler.log'))
  end
end
