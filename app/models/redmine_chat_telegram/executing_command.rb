module RedmineChatTelegram
  class ExecutingCommand < ActiveRecord::Base
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
        message: I18n.t('redmine_chat_telegram.bot.command_canceled'),
        reply_markup: Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true))
    end
  end
end
