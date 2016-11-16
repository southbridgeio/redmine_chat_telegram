module RedmineChatTelegram
  module Commands
    class BotCommand < BaseBotCommand
      @@command_helps = []
      cattr_accessor :command_helps, instance_accessor: false

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

      def command_helps
        [
          "*connect* - #{I18n.t('redmine_chat_telegram.bot.help.connect')}",
          "*new* - #{I18n.t('redmine_chat_telegram.bot.help.new')}",
          "*hot* - #{I18n.t('redmine_chat_telegram.bot.help.hot')}",
          "*me* - #{I18n.t('redmine_chat_telegram.bot.help.me')}",
          "*deadline* - #{I18n.t('redmine_chat_telegram.bot.help.deadline')}",
          "*dl* - #{I18n.t('redmine_chat_telegram.bot.help.deadline')}",
          "*spent* - #{I18n.t('redmine_chat_telegram.bot.help.spent')}",
          "*yspent* - #{I18n.t('redmine_chat_telegram.bot.help.yspent')}",
          "*last* - #{I18n.t('redmine_chat_telegram.bot.help.last')}",
          "*help* - #{I18n.t('redmine_chat_telegram.bot.help.help')}"
        ] + self.class.command_helps
      end

      def executing_command
        @executing_command ||= RedmineChatTelegram::ExecutingCommand
                             .joins(:account)
                             .find_by(telegram_common_accounts: { telegram_id: command.from.id })
      end

      def execute_command
        command_name = command.text.match(/\/(\w+)/)[1]
        send("execute_command_#{command_name}")
      rescue NameError
        # do nothing
      end

      def execute_command_help
        bot.send_message(
          chat_id: command.chat.id,
          text: command_helps.join("\n"),
          parse_mode: 'Markdown')
      end

      def execute_command_new
        RedmineChatTelegram::Commands::NewIssueCommand.new(command, bot).execute
      end

      def execute_find_issues_command
        RedmineChatTelegram::Commands::FindIssuesCommand.new(command, bot, find_issues_logger).execute
      end

      alias_method :execute_command_hot, :execute_find_issues_command
      alias_method :execute_command_me, :execute_find_issues_command
      alias_method :execute_command_dl, :execute_find_issues_command
      alias_method :execute_command_deadline, :execute_find_issues_command

      def find_issues_logger
        RedmineChatTelegram::Commands::FindIssuesCommand::LOGGER
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

      def execute_command_chat
        RedmineChatTelegram::Commands::IssueChatCommand.new(command, bot).execute
      end
    end
  end
end
