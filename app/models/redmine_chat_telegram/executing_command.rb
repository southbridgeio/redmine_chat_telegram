class RedmineChatTelegram::ExecutingCommand < ActiveRecord::Base
  unloadable

  serialize :data

  belongs_to :account, class_name: '::TelegramCommon::Account'

  before_create -> (model) { model.step_number = 1 }

  def continue(command)
    RedmineChatTelegram::Commands::BotCommand.new(command).send("execute_command_#{name}")
  end

  def cancel(command)
    destroy
    TelegramCommon::Bot::MessageSender.call(
      bot_token: RedmineChatTelegram.bot_token,
      chat_id: command.chat.id,
      message: 'Команда отменена.',
      reply_markup: Telegrammer::DataTypes::ReplyKeyboardHide.new(hide_keyboard: true))
  end
end
