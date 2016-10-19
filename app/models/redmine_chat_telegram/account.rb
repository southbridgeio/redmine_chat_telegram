class RedmineChatTelegram::Account < ActiveRecord::Base
  unloadable

  belongs_to :user
end
