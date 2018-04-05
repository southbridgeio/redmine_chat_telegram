module RedmineChatTelegram
  module Commands
    class BotCommand < BaseBotCommand
      @@command_helps = []
      cattr_accessor :command_helps, instance_accessor: false

      def execute
        if executing_command.present? && command.text =~ /\/cancel/
          executing_command.cancel(command)
        elsif executing_command.present?
          executing_command.continue(command)
        else
          execute_command
        end
      end

      def execute_command_new
        RedmineChatTelegram::Commands::NewIssueCommand.new(command).execute
      end

      def execute_find_issues_command
        RedmineChatTelegram::Commands::FindIssuesCommand.new(command, find_issues_logger).execute
      end

      alias execute_command_hot execute_find_issues_command
      alias execute_command_me execute_find_issues_command
      alias execute_command_dl execute_find_issues_command
      alias execute_command_deadline execute_find_issues_command

      def find_issues_logger
        RedmineChatTelegram::Commands::FindIssuesCommand::LOGGER
      end

      def execute_command_spent
        RedmineChatTelegram::Commands::TimeStatsCommand.new(command).execute
      end

      def execute_command_yspent
        RedmineChatTelegram::Commands::TimeStatsCommand.new(command).execute
      end

      def execute_command_last
        RedmineChatTelegram::Commands::LastIssuesNotesCommand.new(command).execute
      end

      def execute_command_connect
        RedmineChatTelegram::Commands::ConnectCommand.new(command, logger).execute
      end

      def execute_command_chat
        RedmineChatTelegram::Commands::IssueChatCommand.new(command).execute
      end

      def execute_command_issue
        RedmineChatTelegram::Commands::EditIssueCommand.new(command).execute
      end

      alias execute_command_task execute_command_issue

      def execute_command_ih
        command.text = '/issue hot'
        execute_command_issue
      end

      alias execute_command_th execute_command_ih

      private

      def executing_command
        @executing_command ||= RedmineChatTelegram::ExecutingCommand
                             .joins(:account)
                             .find_by(telegram_common_accounts: { telegram_id: command.from.id })
      end

      def execute_command
        send("execute_command_#{command_name}")
      rescue NameError
        # do nothing
      end
    end
  end
end
