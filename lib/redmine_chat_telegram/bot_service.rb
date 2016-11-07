module RedmineChatTelegram
  class BotService
    EMAIL_REGEXP = /([^@\s]+@(?:[-a-z0-9]+\.)+[a-z]{2,})/i

    attr_reader :bot, :logger, :command, :issue, :message

    def initialize(command, bot = nil)
      @bot     = bot.present? ? bot : Telegrammer::Bot.new(RedmineChatTelegram.bot_token)
      @command = command
      @issue   = find_issue

      if Rails.env.production?
        FileUtils.mkdir_p(Rails.root.join('log/redmine_chat_telegram'))
        @logger = Logger.new(Rails.root.join('log/redmine_chat_telegram', 'bot.log'))
      else
        @logger = Logger.new(STDOUT)
      end
    end

    def call
      RedmineChatTelegram.set_locale
      execute_command
    end

    def group_chat_created
      issue_url = RedmineChatTelegram.issue_url(issue.id)
      bot.send_message(
        chat_id: command.chat.id,
        text: I18n.t('redmine_chat_telegram.messages.hello', issue_url: issue_url),
        disable_web_page_preview: true)

      message.message = 'chat_was_created'
      message.save!
    end

    def new_chat_participant
      new_chat_participant = command.new_chat_participant

      if command.from.id == new_chat_participant.id
        message.message = 'joined'
      else
        message.message = 'invited'
        message.system_data = chat_user_full_name(new_chat_participant)
      end

      message.save!
    end

    def left_chat_participant
      left_chat_participant = command.left_chat_participant

      if command.from.id == left_chat_participant.id
        message.message = 'left_group'
      else
        message.message = 'kicked'
        message.system_data = chat_user_full_name(left_chat_participant)
      end

      message.save!
    end

    def send_issue_link
      issue_url = RedmineChatTelegram.issue_url(issue.id)
      issue_url_text = "#{issue.subject}\n#{issue_url}"
      bot.send_message(
        chat_id: command.chat.id,
        text: issue_url_text,
        disable_web_page_preview: true)
    end

    def log_message
      message.message = command.text.gsub('/log ', '')
      message.bot_message = false
      message.is_system = false

      journal_text = message.as_text(with_time: false)
      issue.init_journal(
        User.anonymous,
        "_#{I18n.t('redmine_chat_telegram.journal.from_telegram')}:_ \n\n#{journal_text}")

      issue.save!
      message.save!
    end

    def save_message
      message.message = command.text
      message.bot_message = false
      message.is_system = false
      message.save!
    end

    def connect
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

    def execute_command
      if command.chat.type == 'group' && issue.present?
        @message = init_message

        if command.group_chat_created
          group_chat_created

        elsif command.new_chat_participant.present?
          new_chat_participant

        elsif command.left_chat_participant.present?
          left_chat_participant

        elsif command.text =~ /\/task|\/link|\/url/
          send_issue_link

        elsif command.text =~ /\/log/
          log_message

        elsif command.text.present?
          save_message
        end
      elsif command.chat.type == 'private'
        if executing_command.present? && command.text =~ /\/cancel/
          executing_command.cancel(command, bot)
        elsif executing_command.present?
          executing_command.continue(command, bot)
        elsif command.text =~ /\/connect/
          connect
        elsif command.text =~ /\/new/
          RedmineChatTelegram::Commands::NewIssueCommand.new(command, bot).execute
        elsif command.text =~ /\/hot|\/me|\/dl|\/deadline/
          RedmineChatTelegram::Commands::FindIssuesCommand.new(command, bot).execute
        end
      end
    rescue ActiveRecord::RecordNotFound
    # ignore
    rescue Exception => e
      logger.error "UPDATE #{e.class}: #{e.message} \n#{e.backtrace.join("\n")}"
      print e.backtrace.join("\n")
    end

    def chat_user_full_name(telegram_user)
      [telegram_user.first_name, telegram_user.last_name].compact.join ' '
    end

    def user_not_found
      bot.send_message(chat_id: command.chat.id, text: 'User not found')
    end

    def init_message
      telegram_message = TelegramMessage.new(
        issue_id:        issue.id,
        telegram_id:     command.message_id,
        sent_at:         command.date,
        from_id:         command.from.id,
        from_first_name: command.from.first_name,
        from_last_name:  command.from.last_name,
        from_username:   command.from.username,
        is_system:       true,
        bot_message:     true)
    end

    def find_issue
      chat_id = command.chat.id

      begin
        Issue.joins(:telegram_group)
          .find_by!(redmine_chat_telegram_telegram_groups: { telegram_id: chat_id.abs })
      rescue ActiveRecord::RecordNotFound => e
        nil
      rescue Exception => e
        logger.error "#{e.class}: #{e.message}\n#{e.backtrace.join("\n")}"
        nil
      end
    end

    def user
      command.from
    end

    def account
      @account ||= fetch_account
    end

    def executing_command
      @executing_command ||= RedmineChatTelegram::ExecutingCommand
                           .joins(:account)
                           .find_by(telegram_common_accounts: { telegram_id: user.id })
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
