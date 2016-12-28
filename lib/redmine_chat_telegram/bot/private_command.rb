module RedmineChatTelegram
  class Bot
    module PrivateCommand
      private

      def private_common_commands
        %w(connect start help)
      end

      def private_plugin_commands
        %w(new hot me deadline dl spent yspent last chat issue help)
      end

      def private_ext_commands
        []
      end

      def private_commands
        (private_common_commands +
          private_plugin_commands +
          private_ext_commands
        ).uniq
      end

      def handle_private_command
        executing_command = RedmineChatTelegram::ExecutingCommand
                            .joins(:account)
                            .find_by(telegram_common_accounts: { telegram_id: command.from.id })
        if private_commands.include?(command_name) || executing_command.present?
          if private_common_command?
            execute_private_command
          else
            RedmineChatTelegram::Commands::BotCommand.new(command, logger).execute
          end
        else
          send_message(I18n.t('telegram_common.bot.private.group_command'))
        end
      end

      def private_common_command?
        private_common_commands.include?(command_name)
      end
    end
  end
end
