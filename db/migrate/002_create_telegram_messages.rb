class CreateTelegramMessages < ActiveRecord::Migration
  def change
    create_table :telegram_messages do |t|
      t.integer :issue_id
      t.integer :telegram_id
      t.integer :from_id
      t.string :from_first_name
      t.string :from_last_name
      t.string :from_username
      t.datetime :sent_at
      t.text :message
    end
    add_index :telegram_messages, :issue_id
  end
end
