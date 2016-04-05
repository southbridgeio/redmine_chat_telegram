class RedmineChatTelegram::TelegramGroup < ActiveRecord::Base
  unloadable

  belongs_to :issue
end
