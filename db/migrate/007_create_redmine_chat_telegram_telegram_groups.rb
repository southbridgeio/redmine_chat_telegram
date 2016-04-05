class CreateRedmineChatTelegramTelegramGroups < ActiveRecord::Migration
  def up
    create_table :redmine_chat_telegram_telegram_groups do |t|
      t.belongs_to :issue, index: true, foreign_key: true
      t.integer :telegram_id
      t.string :shared_url
      t.datetime :need_to_close_at
      t.datetime :last_notification_at
    end
    add_index :redmine_chat_telegram_telegram_groups, :telegram_id

    Issue.where.not(telegram_id: nil).find_each do |issue|
      issue.create_telegram_group telegram_id: issue.telegram_id.abs,
                                  shared_url:  issue.telegram_chat_url
    end
  end

  def down
    drop_table :redmine_chat_telegram_telegram_groups
  end
end
