module RedmineChatTelegram
  module Commands
    class ConnectCommand < BaseBotCommand
      EMAIL_REGEXP = /([^@\s]+@(?:[-a-z0-9]+\.)+[a-z]{2,})/i

      def execute
        email        = command.text.scan(EMAIL_REGEXP).try(:flatten).try(:first)
        redmine_user = EmailAddress.find_by(address: email).try(:user)

        return user_not_found if redmine_user.nil?

        update_account

        if account.user_id == redmine_user.id
          connect_message = I18n.t('redmine_chat_telegram.bot.connect.already_connected')
        else
          connect_message = I18n.t('redmine_chat_telegram.bot.connect.wait_for_email', email: email)
          TelegramCommon::Mailer.telegram_connect(redmine_user, account).deliver
        end

        bot.send_message(chat_id: command.chat.id, text: connect_message)
      end

      private

      def user_not_found
        bot.send_message(chat_id: command.chat.id, text: 'User not found')
      end

      def user
        command.from
      end

      def account
        @account ||= fetch_account
      end

      def fetch_account
        ::TelegramCommon::Account.where(telegram_id: user.id).first_or_initialize
      end

      def update_account
        account.assign_attributes(
          username:   user.username,
          first_name: user.first_name,
          last_name:  user.last_name,
          active:     true)
        write_log_about_new_user if account.new_record?

        account.save!
      end

      def write_log_about_new_user
        logger.info "New telegram_user #{user.first_name} #{user.last_name} @#{user.username} added!"
      end
    end
  end
end
