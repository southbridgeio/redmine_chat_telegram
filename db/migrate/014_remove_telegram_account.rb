class RemoveTelegramAccount < ActiveRecord::Migration
  def change
    drop_table :redmine_chat_telegram_accounts
  end
end
