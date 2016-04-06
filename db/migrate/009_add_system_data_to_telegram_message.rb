class AddSystemDataToTelegramMessage < ActiveRecord::Migration
  def change
    add_column :telegram_messages, :system_data, :string
  end
end
