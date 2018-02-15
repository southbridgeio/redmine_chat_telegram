module RedmineChatTelegram
  class TelegramGroup < ActiveRecord::Base
    unloadable

    belongs_to :issue
  end
end
