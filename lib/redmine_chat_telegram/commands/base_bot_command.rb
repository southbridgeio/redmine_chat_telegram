module RedmineChatTelegram
  module Commands
    class BaseBotCommand
      attr_reader :command, :bot, :logger

      LOGGER = Logger.new(Rails.root.join('log/chat_telegram', 'bot-command-base.log'))

      def initialize(command, bot, logger = LOGGER)
        @command = command
        @bot = bot
        @logger = logger
      end

      def execute
        raise 'not implemented'
      end

      private

      def send_message(text, params = {})
        message = {chat_id: command.chat.id, text: text, parse_mode: 'HTML'}
        bot.send_message(message.merge(params))
      end

      def account
        @account ||= ::TelegramCommon::Account.find_by!(telegram_id: command.from.id)
      rescue ActiveRecord::RecordNotFound
        bot.send_message(chat_id: command.chat.id, text: 'Аккаунт не найден.')
        nil
      end

      def issue_url(issue)
        Rails.application.routes.url_helpers.issue_url(
          issue,
          host: Setting.host_name,
          protocol: Setting.protocol)
      end
    end
  end
end
