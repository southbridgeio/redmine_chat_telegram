module RedmineChatTelegram
  class Bot
    module PrivateCommand
      private

      def private_common_commands
        %w(start help)
      end

      def private_plugin_commands
        %w(connect new hot me deadline spent yspent last chat help)
      end

      def private_ext_commands
        []
      end

      def private_commands
        ( private_common_commands +
          private_plugin_commands +
          private_ext_commands
        ).uniq
      end

      def handle_private_command
        if private_commands.include?(command_name)
          if private_common_command?
            execute_private_command
          else
            RedmineChatTelegram::Commands::BotCommand.new(command, bot, logger).execute
          end
        else
          send_message(command.chat.id, I18n.t('telegram_common.bot.private.group_command'))
        end
      end

      def private_common_command?
        private_common_commands.include?(command_name)
      end

    end
  end
end
