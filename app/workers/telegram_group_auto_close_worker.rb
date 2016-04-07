class TelegramGroupAutoCloseWorker
  include Sidekiq::Worker
  TELEGRAM_GROUP_AUTO_CLOSE_LOG = Logger.new(Rails.root.join('log/chat_telegram', 'telegram-group-auto-close.log'))

  def perform
    need_to_notify_issues = Issue.open(false).joins(:telegram_group).
        where('redmine_chat_telegram_telegram_groups.last_notification_at <= ?', 12.hours.ago)

    need_to_notify_issues.each do |issue|
      TelegramGroupCloseNotificationWorker.perform_async(issue.id)
    end

    need_to_close_issues = Issue.open(false).joins(:telegram_group).
        where('redmine_chat_telegram_telegram_groups.need_to_close_at <= ?', Time.now)

    need_to_close_issues.each do |issue|
      telegram_id = issue.telegram_group.telegram_id

      issue.telegram_group.destroy
      TelegramGroupCloseWorker.perform_async(telegram_id)
    end

  rescue ActiveRecord::RecordNotFound => e
    # ignore
  end
end
