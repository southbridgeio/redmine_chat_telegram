class RemoveChatTelegramAttributesFromIssues < ActiveRecord::Migration
  def up
    remove_index :issues, :telegram_id
    remove_column :issues, :telegram_id
    remove_column :issues, :telegram_chat_url
  end

  def down
    add_column :issues, :telegram_chat_url, :string
    add_column :issues, :telegram_id, :integer
    add_index :issues, :telegram_id
  end
end
