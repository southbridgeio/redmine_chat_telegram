module RedmineChatTelegram
  module Commands
    class BaseBotCommand
      attr_reader :command, :logger

      LOGGER = Logger.new(Rails.root.join('log/chat_telegram', 'bot-command-base.log'))

      def initialize(command, logger = LOGGER)
        @command = command
        @logger = logger
      end

      def execute
        raise 'not implemented'
      end

      private

      def command_name
        command.text.match(/^\/(\w+)/)[1]
      end

      def command_arguments
        command.text.match(/^\/\w+ (.+)$/).try(:[], 1)
      end

      def arguments_help
        I18n.t("redmine_chat_telegram.bot.arguments_help.#{command_name}")
      end

      def send_message(text, params = {})
        message_params = {
          chat_id: chat_id,
          message: text,
          bot_token: bot_token,
        }.merge(params)

        ::TelegramCommon::Bot::MessageSender.call(message_params)
      end

      def account
        @account ||= ::TelegramCommon::Account.find_by!(telegram_id: command.from.id)
      rescue ActiveRecord::RecordNotFound
        send_message('Аккаунт не найден.')
        nil
      end

      def issue_url(issue)
        Rails.application.routes.url_helpers.issue_url(
          issue,
          host: Setting.host_name,
          protocol: Setting.protocol)
      end

      def chat_id
        command.chat.id
      end

      def bot_token
        RedmineChatTelegram.bot_token
      end
    end
  end
end
