module RedmineChatTelegram
  module Commands
    class BaseBotCommand
      attr_reader :command, :bot, :logger

      def initialize(command, bot, logger = nil)
        @command = command
        @bot = bot
        @logger = logger
      end

      def execute
        raise 'not implemented'
      end

      protected

      def account
        @account ||= ::TelegramCommon::Account.find_by!(telegram_id: command.from.id)
      rescue ActiveRecord::RecordNotFound
        bot.send_message(chat_id: command.chat.id, text: 'Аккаунт не найден.')
        nil
      end
    end
  end
end
