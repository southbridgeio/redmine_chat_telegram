class RedmineChatTelegram::Bot < TelegramCommon::Bot
  include PrivateCommand
  include GroupCommand

  attr_reader :logger, :command, :issue

  def initialize(command)
    @logger = Logger.new(Rails.root.join('log/chat_telegram', 'bot.log'))
    @command = initialize_command(command)
  end

  private

  def initialize_command(command)
    command.is_a?(Telegrammer::DataTypes::Message) ? command : Telegrammer::DataTypes::Message.new(command)
  end

  def execute_command
    if private_command?
      handle_private_command
    else
      handle_group_command
    end
  end

  def private_help_message
    help_command_list(private_commands, namespace: 'redmine_chat_telegram', type: 'private')
  end

  def group_help_message
    help_command_list(group_commands, namespace: 'redmine_chat_telegram', type: 'group') + "\n#{I18n.t('redmine_chat_telegram.bot.group.help.hint')}"
  end

  def bot_token
    RedmineChatTelegram.bot_token
  end
end
