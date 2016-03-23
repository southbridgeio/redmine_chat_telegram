module ChatTelegram
  module IssuePatch
    def self.included(base) # :nodoc:
      base.class_eval do
        unloadable

        has_many :telegram_messages
      end
    end

  end
end
Issue.send(:include, ChatTelegram::IssuePatch)
