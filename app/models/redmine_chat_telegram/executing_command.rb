class RedmineChatTelegram::ExecutingCommand < ActiveRecord::Base
  unloadable

  serialize :data

  belongs_to :account, class_name: '::TelegramCommon::Account'

  before_create -> (model) { model.step_number = 1 }

  def continue(command, bot)
    return unless name == 'new'
    RedmineChatTelegram::Commands::NewIssueCommand.new(command, bot).execute
  end

  def cancel(command, bot)
    return unless name == 'new'
    destroy
    bot.send_message(
      chat_id: command.chat.id,
      text: 'Команда создания задачи отменена.',
      reply_markup: Telegrammer::DataTypes::ReplyKeyboardHide.new(hide_keyboard: true))
  end
end
