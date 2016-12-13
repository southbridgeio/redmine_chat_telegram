class TelegramGroupDailyReportWorker
  include Sidekiq::Worker
  include Redmine::I18n

  TELEGRAM_GROUP_DAILY_REPORT_LOG = Logger.new(Rails.root.join('log/chat_telegram', 'telegram-group-daily-report.log'))

  def perform(issue_id, yesterday_string)
    RedmineChatTelegram.set_locale

    yesterday = Date.parse yesterday_string
    time_from = yesterday.beginning_of_day
    time_to   = yesterday.end_of_day

    issue             = Issue.find(issue_id)
    telegram_messages = issue.telegram_messages
                             .where('sent_at >= ? and sent_at <= ?', time_from, time_to)
                             .where(is_system: false, bot_message: false)
                             .where.not(from_id: [Setting.plugin_redmine_chat_telegram['bot_id'],
                                                  Setting.plugin_redmine_chat_telegram['robot_id']])

    if telegram_messages.present?
      date_string       = format_date(yesterday)
      user_names        = telegram_messages.map(&:author_name).uniq
      joined_user_names = user_names.join(', ').strip
      users_count       = Pluralization.pluralize(user_names.count,
                                                  'человек',
                                                  'человекa',
                                                  'человек',
                                                  'человек')
      messages_count = Pluralization.pluralize(telegram_messages.count,
                                               'сообщение',
                                               'сообщения',
                                               'сообщений',
                                               'сообщений')

      users_text    = [user_names.count, users_count].join ' '
      messages_text = [telegram_messages.count, messages_count].join ' '
      journal_text  =
        "_#{I18n.t 'redmine_chat_telegram.journal.from_telegram'}:_ \n\n" +
        I18n.t('redmine_chat_telegram.journal.daily_report',
               date:           date_string,
               users:          joined_user_names,
               messages_count: messages_text,
               users_count:    users_text)

      begin
        issue.init_journal(User.anonymous, journal_text)
        issue.save
      rescue ActiveRecord::StaleObjectError
        issue.reload
        retry
      end
    end
  rescue ActiveRecord::RecordNotFound => e
    # ignore
  end
end
