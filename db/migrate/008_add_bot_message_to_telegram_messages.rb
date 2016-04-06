class AddBotMessageToTelegramMessages < ActiveRecord::Migration
  def change
    add_column :telegram_messages, :bot_message, :boolean, default: false, null: false
  end
end
