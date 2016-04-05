class AddIsSystemToTelegramMessage < ActiveRecord::Migration
  def change
    add_column :telegram_messages, :is_system, :boolean, default: false
  end
end
