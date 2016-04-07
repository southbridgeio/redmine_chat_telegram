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

        date_string = format_date(yesterday)
        user_names = telegram_messages.map(&:author_name).uniq
        joined_user_names = user_names.join(', ')
        journal_text = I18n.t('redmine_chat_telegram.journal.daily_report', date: date_string, users: joined_user_names, messages_count: telegram_messages.size, users_count: user_names.count)
        issue.init_journal(User.current, "_#{ I18n.t 'redmine_chat_telegram.journal.from_telegram' }:_ \n\n#{journal_text}")
        issue.save
      end
    end
  rescue ActiveRecord::RecordNotFound => e
    # ignore
  end
end
