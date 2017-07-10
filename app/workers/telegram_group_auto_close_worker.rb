class TelegramGroupAutoCloseWorker
  include Sidekiq::Worker
  TELEGRAM_GROUP_AUTO_CLOSE_LOG = Logger.new(Rails.root.join('log/chat_telegram', 'telegram-group-auto-close.log'))

  def perform
    notify_chats_about_closed_issues
    close_old_chats
  end

  private

  def notify_chats_about_closed_issues
    need_to_notify_issues.find_each do |issue|
      TelegramGroupCloseNotificationWorker.perform_async(issue.id)
    end
  end

  def need_to_notify_issues
    issues = Issue.joins(:telegram_group)
                  .where('redmine_chat_telegram_telegram_groups.last_notification_at <= ?', 12.hours.ago.change(min: 59, sec: 59))

    if close_issue_status_ids.present?
      issues = issues.where(status_id: close_issue_status_ids)
    else
      issues = issues.open(false)
    end

    issues
  end

  def close_old_chats
    need_to_close_issues.find_each do |issue|
      telegram_id = issue.telegram_group.telegram_id

      issue.telegram_group.destroy
      TelegramGroupCloseWorker.perform_async(telegram_id)
    end
  end

  def need_to_close_issues
    if close_issue_status_ids.present?
      Issue.joins(:telegram_group)
        .where(status_id: close_issue_status_ids)
        .where('redmine_chat_telegram_telegram_groups.need_to_close_at <= ?', Time.now)
    else
      Issue.open(false).joins(:telegram_group)
        .where('redmine_chat_telegram_telegram_groups.need_to_close_at <= ?', Time.now)
    end
  end

  def close_issue_status_ids
    @close_issue_status_ids ||= Setting['plugin_redmine_chat_telegram']['close_issue_statuses']
  end
end
