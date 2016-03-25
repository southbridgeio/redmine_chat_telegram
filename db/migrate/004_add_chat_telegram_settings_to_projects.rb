class AddChatTelegramSettingsToProjects < ActiveRecord::Migration
  def up
    add_column :projects, :chat_telegram_settings, :text
  end

  def down
    remove_column :projects, :chat_telegram_settings
  end
end
