class IncreaseTelegramIdLimit < ActiveRecord::Migration
  def change
    change_column :redmine_chat_telegram_telegram_groups, :telegram_id, :integer, limit: 8
  end
end
