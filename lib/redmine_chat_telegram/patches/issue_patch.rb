module RedmineChatTelegram
  module Patches
    module IssuePatch
      def self.included(base) # :nodoc:
        base.class_eval do
          unloadable

          has_many :telegram_messages
        end
      end

    end
  end
end
Issue.send(:include, RedmineChatTelegram::Patches::IssuePatch)
