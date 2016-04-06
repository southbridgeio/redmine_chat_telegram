class TelegramGroupDailyReportWorker
  include Sidekiq::Worker
  include Redmine::I18n

  TELEGRAM_GROUP_DAILY_REPORT_LOG = Logger.new(Rails.root.join('log/chat_telegram', 'telegram-group-daily-report.log'))

  def perform
    if Setting.plugin_redmine_chat_telegram['daily_report']
      yesterday = 12.hours.ago
      time_from = yesterday.beginning_of_day
      time_to   = yesterday.end_of_day

      Issue.joins(:telegram_messages).where('telegram_messages.sent_at >= ? and telegram_messages.sent_at <= ?',
                                            time_from, time_to).find_each do |issue|
        telegram_messages = issue.telegram_messages.
            where('sent_at >= ? and sent_at <= ?', time_from, time_to).
            where(is_system: false, bot_message: false)

        # TODO: Localize it
        date_string = format_date(yesterday)
        user_names = telegram_messages.map(&:author_name).uniq
        joined_user_names = user_names.join(', ')
        journal_text = "За #{date_string} в чате переписывались #{joined_user_names}, всего #{telegram_messages.size} реплик. Всего в чате было #{user_names.count} человек."
        issue.init_journal(User.current, "_Из чата Telegram:_ \n\n#{journal_text}")
        issue.save
      end
    end
  rescue ActiveRecord::RecordNotFound => e
    # ignore
  end
end
