class RedmineChatTelegram::ExecutingCommand < ActiveRecord::Base
  unloadable

  serialize :data

  belongs_to :account, class_name: '::TelegramCommon::Account'

  before_create -> (model) { model.step_number = 1 }

  def continue(command, bot)
    if name == 'new'
      RedmineChatTelegram::Commands::NewIssueCommand.new(command, bot).execute
    end
  end

  def cancel(command, bot)
    if name == 'new'
      destroy
      bot.send_message(
        chat_id: command.chat.id,
        text: 'Команда создания задачи отменена.',
        reply_markup: Telegrammer::DataTypes::ReplyKeyboardHide.new(hide_keyboard: true))
    end
  end
end
