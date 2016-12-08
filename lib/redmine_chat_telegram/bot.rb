class RedmineChatTelegram::Bot < TelegramCommon::Bot
  include PrivateCommand
  include GroupCommand

  attr_reader :bot, :logger, :command, :issue

  def initialize(command, bot = nil)
    @bot = bot.present? ? bot : Telegrammer::Bot.new(RedmineChatTelegram.bot_token)
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
    help_command_list(group_commands, namespace: 'redmine_chat_telegram', type: 'group')
  end
end
