class AddTokenToTelegramAccount < ActiveRecord::Migration
  def up
    add_column :redmine_chat_telegram_accounts, :token, :string
  end

  def down
    remove_column :redmine_chat_telegram_accounts, :token
  end
end
