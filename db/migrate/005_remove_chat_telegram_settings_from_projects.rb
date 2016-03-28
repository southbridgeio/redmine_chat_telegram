class RemoveChatTelegramSettingsFromProjects < ActiveRecord::Migration
  def up
    remove_column :projects, :chat_telegram_settings
  end

  def down
    add_column :projects, :chat_telegram_settings, :text
  end
end
