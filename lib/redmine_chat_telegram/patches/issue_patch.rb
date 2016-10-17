module RedmineChatTelegram
  module Patches
    module IssuePatch
      def self.included(base) # :nodoc:
        base.class_eval do
          unloadable

          has_many :telegram_messages, dependent: :destroy
          has_one :telegram_group, class_name: 'RedmineChatTelegram::TelegramGroup'

          before_save :set_need_to_close, :reset_need_to_close
          before_destroy :close_chat


          def set_need_to_close
            if closing? and telegram_group.present?
              telegram_group.update need_to_close_at:     2.weeks.from_now,
                                    last_notification_at: (1.week.from_now - 12.hours)

            end
          end

          def reset_need_to_close
            if reopening? and telegram_group.present?
              telegram_group.update need_to_close_at:     nil,
                                    last_notification_at: nil
            end
          end
        end

        private

        def close_chat
          if telegram_group.present?
            TelegramGroupCloseWorker.perform_async(telegram_group.telegram_id)
            telegram_group.destroy
          end
        end

      end

    end
  end
end
Issue.send(:include, RedmineChatTelegram::Patches::IssuePatch)
