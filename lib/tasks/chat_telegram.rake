def set_telegram_id(message, telegram_chat_id)
  chat_title = message.chat.title
  issue_id   = chat_title.match(/#(\d+)/)[1]
  issue      = Issue.find(issue_id)

  begin
    issue.telegram_id = telegram_chat_id
    issue.save
  rescue ActiveRecord::StaleObjectError
    issue.reload
    retry
  end
  issue
end

def chat_user_full_name(telegram_user)
  [telegram_user.first_name, telegram_user.last_name].compact.join
end

namespace :chat_telegram do
  # bundle exec rake chat_telegram:bot PID_DIR='/tmp'
  desc "Runs telegram bot process (options: PID_DIR='/pid/dir')"
  task :bot => :environment do
    LOG = Rails.env.production? ? Logger.new(Rails.root.join('log/chat_telegram', 'bot.log')) : Logger.new(STDOUT)

    Process.daemon(true, true) if Rails.env.production?

    if ENV['PID_DIR']
      pid_dir = ENV['PID_DIR']
      PidFile.new(piddir: pid_dir, pidfile: 'telegram-chat-bot.pid')
    else
      PidFile.new(pidfile: 'telegram-chat-bot.pid')
    end

    at_exit { LOG.error 'aborted by some reasons' }

    Signal.trap('TERM') do
      at_exit { LOG.error 'Aborted with TERM signal' }
      abort 'Aborted with TERM signal'
    end
    Signal.trap('QUIT') do
      at_exit { LOG.error 'Aborted with QUIT signal' }
      abort 'Aborted with QUIT signal'
    end
    Signal.trap('HUP') do
      at_exit { LOG.error 'Aborted with HUP signal' }
      abort 'Aborted with HUP signal'
    end

    LOG.info 'Start daemon...'

    token = Setting.plugin_redmine_chat_telegram['bot_token']

    unless token.present?
      LOG.error 'Telegram Bot Token not found. Please set it in the plugin config web-interface.'
      exit
    end

    LOG.info 'Telegram Bot: Connecting to telegram...'
    bot      = Telegrammer::Bot.new(token)
    bot_name = bot.me.username

    until bot_name.present?

      LOG.error 'Telegram Bot Token is invalid or Telegram API is in downtime. I will try again after minute'
      sleep 60

      LOG.info 'Telegram Bot: Connecting to telegram...'
      bot      = Telegrammer::Bot.new(token)
      bot_name = bot.me.username

    end

    LOG.info "#{bot_name}: connected"
    LOG.info "#{bot_name}: waiting for new messages in group chats..."

    bot.get_updates(fail_silently: false) do |message|
      begin
        telegram_chat_id = message.chat.id
        telegram_id      = message.message_id
        sent_at          = message.date

        from_id         = message.from.id
        from_first_name = message.from.first_name
        from_last_name  = message.from.last_name
        from_username   = message.from.username

        if message.group_chat_created
          issue = set_telegram_id(message, telegram_chat_id)

          issue_url = RedmineChatTelegram.issue_url(issue.id)
          bot.send_message(chat_id: telegram_chat_id, text: "Hello, everybody! This is a chat for issue: #{issue_url}")
          message_text     = 'Chat created'
          telegram_message = TelegramMessage.create issue_id:       issue.id,
                                                    telegram_id:    telegram_id,
                                                    sent_at:        sent_at, message: message_text,
                                                    from_id:        from_id, from_first_name: from_first_name,
                                                    from_last_name: from_last_name, from_username: from_username
        else
          issue = Issue.find_by(telegram_id: telegram_chat_id)
          issue = set_telegram_id(message, telegram_chat_id) unless issue.present?

          if message.new_chat_participant.present?
            new_chat_participant = message.new_chat_participant
            message_text         = if message.from.id == new_chat_participant.id
                                     'joined to the group'
                                   else
                                     "invited #{chat_user_full_name(new_chat_participant)}"
                                   end
            telegram_message     = TelegramMessage.create issue_id:       issue.id,
                                                          telegram_id:    telegram_id,
                                                          sent_at:        sent_at, message: message_text,
                                                          from_id:        from_id, from_first_name: from_first_name,
                                                          from_last_name: from_last_name, from_username: from_username
          elsif message.left_chat_participant.present?
            left_chat_participant = message.left_chat_participant
            message_text          = if message.from.id == left_chat_participant.id
                                      'left the group'
                                    else
                                      "kicked #{chat_user_full_name(left_chat_participant)}"
                                    end
            telegram_message      = TelegramMessage.create issue_id:       issue.id,
                                                           telegram_id:    telegram_id,
                                                           sent_at:        sent_at, message: message_text,
                                                           from_id:        from_id, from_first_name: from_first_name,
                                                           from_last_name: from_last_name, from_username: from_username

          elsif message.text.present? and message.chat.type == 'group'
            issue_url = RedmineChatTelegram.issue_url(issue.id)

            message_text = message.text

            if message_text.include?('/task') or message_text.include?('/link') or message_text.include?('/url')
              bot.send_message(chat_id: telegram_chat_id, text: "#{issue.subject}\n#{issue_url}")

              next unless message_text.gsub('/task', '').gsub('/link', '').gsub('/url', '').strip.present?

            end

            telegram_message = TelegramMessage.new issue_id:       issue.id,
                                                   telegram_id:    telegram_id,
                                                   sent_at:        sent_at, message: message_text,
                                                   from_id:        from_id, from_first_name: from_first_name,
                                                   from_last_name: from_last_name, from_username: from_username

            if message_text.include?('/log')
              telegram_message.message = message_text.gsub('/log', '')

              journal_text = telegram_message.as_text(with_time: false)

              issue.init_journal(User.current, "_Из Telegram:_ \n\n#{journal_text}")
              issue.save
            end

            telegram_message.save!

          end
        end

      rescue Exception => e
        LOG.error "#{e.class}: #{e.message}"
        print e.backtrace.join("\n")
      end
    end
  end
end
