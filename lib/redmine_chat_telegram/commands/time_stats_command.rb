module RedmineChatTelegram
  module Commands
    class TimeStatsCommand < BaseBotCommand
      def execute
        return unless account.present?
        bot.send_message(chat_id: command.chat.id, text: message_text)
      end

      private

      def command_name
        command.text.match(/\/(\w+)/)[1]
      end

      def hours_sum
        {
          'spent' => TimeEntry.where(spent_on: Date.today, user: account.user).sum(:hours),
          'yspent' => TimeEntry.where(spent_on: Date.yesterday, user: account.user).sum(:hours)
        }
      end

      def message_text
        I18n.t("redmine_chat_telegram.bot.#{command_name}", hours: hours_sum[command_name])
      end
    end
  end
end
