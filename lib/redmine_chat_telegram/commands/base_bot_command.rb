module RedmineChatTelegram
  module Commands
    class BaseBotCommand
      attr_reader :command, :bot

      def initialize(command, bot)
        @command = command
        @bot = bot
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
