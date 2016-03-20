class AddTelegramChatUrlToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :telegram_chat_url, :string
  end
end
