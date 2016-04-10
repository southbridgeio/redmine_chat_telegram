module RedmineChatTelegram
  module Hooks
    class IssuesEditHook < Redmine::Hook::ViewListener

      def controller_issues_edit_after_save(context={})
        issue = context[:issue]
        if issue.telegram_group.present?
          telegram_id = issue.telegram_group.telegram_id
          TelegramIssueNotificationsWorker.perform_async(telegram_id, context[:journal].id)
        end
      end
    end
  end
end
