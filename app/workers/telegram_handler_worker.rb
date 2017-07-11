class TelegramHandlerWorker
  include Sidekiq::Worker
  sidekiq_options queue: :telegram

  def perform(params)
    update = Telegram::Bot::Types::Update.new(params)

    types = %w(inline_query
                   chosen_inline_result
                   callback_query
                   edited_message
                   message
                   channel_post
                   edited_channel_post)
    message = types.inject(nil) { |acc, elem| acc || update.send(elem) }

    if message.present?
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
