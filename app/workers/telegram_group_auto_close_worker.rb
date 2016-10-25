class TelegramGroupAutoCloseWorker
  include Sidekiq::Worker
  TELEGRAM_GROUP_AUTO_CLOSE_LOG = Logger.new(Rails.root.join('log/chat_telegram', 'telegram-group-auto-close.log'))

  def perform
    if Setting['plugin_redmine_chat_telegram']['close_issue_statuses'].present?
      need_to_notify_issues = Issue.joins(:telegram_group)
                              .where(status_id: Setting['plugin_redmine_chat_telegram']['close_issue_statuses'])
                              .where('redmine_chat_telegram_telegram_groups.last_notification_at <= ?', 12.hours.ago)
    else
      need_to_notify_issues = Issue.open(false).joins(:telegram_group)
                              .where('redmine_chat_telegram_telegram_groups.last_notification_at <= ?', 12.hours.ago)
    end

    need_to_notify_issues.find_each do |issue|
      TelegramGroupCloseNotificationWorker.perform_async(issue.id)
    end

    if Setting['plugin_redmine_chat_telegram']['close_issue_statuses'].present?
      need_to_close_issues = Issue.joins(:telegram_group)
                             .where(status_id: Setting['plugin_redmine_chat_telegram']['close_issue_statuses'])
                             .where('redmine_chat_telegram_telegram_groups.need_to_close_at <= ?', Time.now)
    else
      need_to_close_issues = Issue.open(false).joins(:telegram_group)
                             .where('redmine_chat_telegram_telegram_groups.need_to_close_at <= ?', Time.now)
    end

    need_to_close_issues.find_each do |issue|
      telegram_id = issue.telegram_group.telegram_id

      issue.telegram_group.destroy
      TelegramGroupCloseWorker.perform_async(telegram_id)
    end

  rescue ActiveRecord::RecordNotFound => e
    # ignore
  end
end
