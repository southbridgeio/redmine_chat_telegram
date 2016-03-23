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
        if message.text.present? and message.chat.type == 'group'

          chat_title   = message.chat.title
          issue_id     = chat_title.match(/#(\d+)/)[1]
          telegram_id  = message.message_id
          sent_at      = message.date
          message_text = message.text

          from_id         = message.from.id
          from_first_name = message.from.first_name
          from_last_name  = message.from.last_name
          from_username   = message.from.username

          TelegramMessage.create issue_id:       issue_id,
                                 telegram_id:    telegram_id, sent_at: sent_at, message: message_text,
                                 from_id:        from_id, from_first_name: from_first_name,
                                 from_last_name: from_last_name, from_username: from_username
        end

      rescue Exception => e
        LOG.error "#{e.class}: #{e.message}"
      end
    end
  end
end
