class AddTelegramIdToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :telegram_id, :integer
    add_index :issues, :telegram_id
  end
end
