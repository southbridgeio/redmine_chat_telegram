class AddTimestampsToTelegramMessages < ActiveRecord::Migration
  def change
    add_column :telegram_messages, :created_on, :timestamp
    add_column :telegram_messages, :updated_on, :timestamp
  end
end
