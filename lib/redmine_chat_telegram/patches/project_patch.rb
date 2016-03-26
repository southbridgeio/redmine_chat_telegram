module RedmineChatTelegram
  module Patches
    module ProjectPatch
      def self.included(base) # :nodoc:
        base.class_eval do
          unloadable

          store :chat_telegram_settings, accessors: %w(telegram_group_creator_role)

          def everybody_can_create_telegram_group?
            telegram_group_creator_role == 'all' or !telegram_group_creator_role.present?
          end
        end
      end

    end
  end
end
Project.send(:include, RedmineChatTelegram::Patches::ProjectPatch)
