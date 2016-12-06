class RedmineChatTelegram::Bot < TelegramCommon::Bot
  include GroupCommand

  attr_reader :bot, :logger, :command, :issue

  def initialize(command, bot = nil)
    @bot = bot.present? ? bot : Telegrammer::Bot.new(RedmineChatTelegram.bot_token)
    @logger = Logger.new(Rails.root.join('log/chat_telegram', 'bot.log'))
    @command = initialize_command(command)
  end

  def call
    RedmineChatTelegram.set_locale
    execute_command
  end

  private

  def initialize_command(command)
    command.is_a?(Telegrammer::DataTypes::Message) ? command : Telegrammer::DataTypes::Message.new(command)
  end

  def execute_command
    if private_command?
      RedmineChatTelegram::Commands::BotCommand.new(command, bot, logger).execute
    else
      handle_group_message
    end
  end
end
