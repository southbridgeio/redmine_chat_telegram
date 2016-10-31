class RedmineChatTelegram::Account < ActiveRecord::Base
  unloadable

  belongs_to :user
  has_one :executing_command
end
