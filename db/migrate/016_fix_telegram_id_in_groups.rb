class FixTelegramIdInGroups < ActiveRecord::Migration
  def up
    RedmineChatTelegram::TelegramGroup.where('telegram_id > 0').each do |group|
      group.update_column(:telegram_id, -group.telegram_id)
    end
  end
end