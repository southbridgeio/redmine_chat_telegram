module RedmineChatTelegram
  module Commands
    class IssueChatCommand < BaseBotCommand

      def execute
        return unless account.present?
        execute_command
      end

      def send_help
        message_text = I18n.t('redmine_chat_telegram.bot.chat.help')
        bot.send_message(chat_id: command.chat.id, text: message_text)
      end

      def issue
        issue_id = command.text.match(/^\/chat (create|info|close) (\d+)$/)[2]
        @issue ||= Issue.visible(account.user).find(issue_id)
      end

      def create_issue_chat
        if account.user.allowed_to?(:create_telegram_chat, issue.project)
          creating_chat_message = I18n.t('redmine_chat_telegram.bot.creating_chat')
          bot.send_message(chat_id: command.chat.id, text: creating_chat_message)

          RedmineChatTelegram::GroupChatCreator.new(issue, account.user).run

          issue.reload
          message_text = I18n.t('redmine_chat_telegram.journal.chat_was_created',
                                telegram_chat_url: issue.telegram_group.shared_url)

          bot.send_message(chat_id: command.chat.id, text: message_text, parse_mode: 'HTML')
        else
          access_denied
        end
      end

      def close_issue_chat
        if account.user.allowed_to?(:close_telegram_chat, issue.project)
          RedmineChatTelegram::GroupChatDestroyer.new(issue, account.user).run
          message_text = I18n.t('redmine_chat_telegram.bot.chat.destroyed')
          bot.send_message(chat_id: command.chat.id, text: message_text, parse_mode: 'HTML')
        else
          access_denied
        end
      end

      def send_chat_info
        unless account.user.allowed_to?(:view_telegram_chat_link, issue.project)
          access_denied
          return
        end

        chat = issue.telegram_group
        if chat.present?
          bot.send_message(chat_id: command.chat.id, text: chat.shared_url)
        else
          message_text = I18n.t('redmine_chat_telegram.bot.chat.chat_not_found')
          bot.send_message(chat_id: command.chat.id, text: message_text)
        end
      end

      def access_denied
        message_text = I18n.t('redmine_chat_telegram.bot.access_denied')
        bot.send_message(chat_id: command.chat.id, text: message_text, parse_mode: 'HTML')
      end

      def execute_command
        case command.text
        when '/chat'
          send_help
        when %r(^/chat create \d+$)
          create_issue_chat
        when %r(^/chat close \d+$)
          close_issue_chat
        when %r(^/chat info \d+$)
          send_chat_info
        else
          message_text = I18n.t('redmine_chat_telegram.bot.chat.incorrect_command') + "\n" +
                         I18n.t('redmine_chat_telegram.bot.chat.help')
          bot.send_message(chat_id: command.chat.id, text: message_text)
        end
      rescue ActiveRecord::RecordNotFound
        message_text = I18n.t('redmine_chat_telegram.bot.chat.issue_not_found')
        bot.send_message(chat_id: command.chat.id, text: message_text)
      end
    end
  end
end
