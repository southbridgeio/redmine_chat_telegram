class AddTokenToTelegramAccount < ActiveRecord::Migration
  def up
    add_column :redmine_chat_telegram_accounts, :token, :string
    RedmineChatTelegram::Account.find_each { |telegram_account| telegram_account.update_attribute(:token, Redmine::Utils.random_hex(20)) }
  end

  def down
    remove_column :redmine_chat_telegram_accounts, :token
  end
end
