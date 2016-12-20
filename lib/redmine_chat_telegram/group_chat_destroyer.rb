module RedmineChatTelegram
  class GroupChatDestroyer
    attr_reader :issue, :user

    def initialize(issue, user)
      @issue = issue
      @user = user
    end

    def run
      telegram_id = issue.telegram_group.telegram_id

      issue.telegram_group.destroy

      issue.init_journal(user, I18n.t('redmine_chat_telegram.journal.chat_was_closed'))

      TelegramGroupCloseWorker.perform_async(telegram_id, user.id) if issue.save
    end
  end
end
