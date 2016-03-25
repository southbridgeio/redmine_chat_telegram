module RedmineChatTelegram
  module Patches
    module ProjectPatch
      def self.included(base) # :nodoc:
        base.class_eval do
          unloadable

          store :chat_telegram_settings, accessors: %w(creator_telegram_group_ids)

        end
      end

    end
  end
end
Project.send(:include, RedmineChatTelegram::Patches::ProjectPatch)
