# This is duplication of the same worker from intouch plugin
# We need to join it in common module

class TelegramMessageSenderWorker
  include Sidekiq::Worker
  sidekiq_options queue: :telegram,
                  rate:  {
                    name:   'telegram_rate_limit',
                    limit:  15,
                    period: 1
                  }

  TELEGRAM_MESSAGE_SENDER_LOG        = Logger.new(Rails.root.join('log/chat_telegram', 'telegram-message-sender.log'))
  TELEGRAM_MESSAGE_SENDER_ERRORS_LOG = Logger.new(Rails.root.join('log/chat_telegram', 'telegram-message-sender-errors.log'))

  def perform(telegram_id, message)
    token = Setting.plugin_redmine_telegram_common['bot_token']
    bot   = Telegram::Bot::Client.new(token)

    # Group telegram_id is negative for Telegram::Bot
    bot.api.send_message(chat_id: -telegram_id.abs,
                     text: message,
                     disable_web_page_preview: true,
                     parse_mode: 'HTML')

    TELEGRAM_MESSAGE_SENDER_LOG.info "telegram_id: #{telegram_id}\tmessage: #{message}"

  rescue Telegram::Bot::Exceptions::ResponseError => e

    TELEGRAM_MESSAGE_SENDER_ERRORS_LOG.info "MESSAGE: #{message}"

    telegram_user = RedmineChatTelegram::TelegramGroup.find_by(telegram_id: telegram_id)

    if e.message.include?('429') || e.message.include?('retry later')

      TELEGRAM_MESSAGE_SENDER_ERRORS_LOG.error "429 retry later error. retry to send after 5 seconds\ntelegram_id: #{telegram_id}\tmessage: #{message}"
      TelegramMessageSenderWorker.perform_in(5.seconds, telegram_id, message)

    else

      TELEGRAM_MESSAGE_SENDER_ERRORS_LOG.error "#{e.class}: #{e.message}"
      TELEGRAM_MESSAGE_SENDER_ERRORS_LOG.debug telegram_user.inspect.to_s

    end
  end
end
