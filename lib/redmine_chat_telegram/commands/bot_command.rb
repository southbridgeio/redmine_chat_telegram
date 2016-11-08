module RedmineChatTelegram
  module Commands
    class BotCommand < BaseBotCommand

      def execute
        if executing_command.present? && command.text =~ /\/cancel/
          executing_command.cancel(command, bot)
        elsif executing_command.present?
          executing_command.continue(command, bot)
        else
          execute_command
        end
      end

      private

      def executing_command
        @executing_command ||= RedmineChatTelegram::ExecutingCommand
                             .joins(:account)
                             .find_by(telegram_common_accounts: { telegram_id: command.from.id })
      end

      def execute_command
        command_name = command.text.match(/\/(\w+)/)[1]
        send("execute_command_#{ command_name }")
      rescue NameError
        # do nothing
      end

      def execute_command_new
        RedmineChatTelegram::Commands::NewIssueCommand.new(command, bot).execute
      end

      def execute_command_hot
        RedmineChatTelegram::Commands::FindIssuesCommand.new(command, bot).execute
      end

      def execute_command_me
        RedmineChatTelegram::Commands::FindIssuesCommand.new(command, bot).execute
      end

      def execute_command_dl
        RedmineChatTelegram::Commands::FindIssuesCommand.new(command, bot).execute
      end

      def execute_command_deadline
        RedmineChatTelegram::Commands::FindIssuesCommand.new(command, bot).execute
      end

      def execute_command_spent
        RedmineChatTelegram::Commands::TimeStatsCommand.new(command, bot).execute
      end

      def execute_command_yspent
        RedmineChatTelegram::Commands::TimeStatsCommand.new(command, bot).execute
      end

      def execute_command_last
        RedmineChatTelegram::Commands::LastIssuesNotesCommand.new(command, bot).execute
      end

      def execute_command_connect
        RedmineChatTelegram::Commands::ConnectCommand.new(command, bot, logger).execute
      end
    end
  end
end
