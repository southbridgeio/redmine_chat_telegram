def chat_user_full_name(telegram_user)
  [telegram_user.first_name, telegram_user.last_name].compact.join
end

def chat_telegram_bot_init
  Process.daemon(true, true) if Rails.env.production?

  tries = 0
  begin
    tries += 1

    if ENV['PID_DIR']
      pid_dir = ENV['PID_DIR']
      PidFile.new(piddir: pid_dir, pidfile: 'telegram-chat-bot.pid')
    else
      PidFile.new(pidfile: 'telegram-chat-bot.pid')
    end

  rescue PidFile::DuplicateProcessError => e
    LOG.error "#{e.class}: #{e.message}"
    pid = e.message.match(/Process \(.+ - (\d+)\) is already running./)[1].to_i

    LOG.info "Kill process with pid: #{pid}"

    Process.kill('HUP', pid)
    if tries < 4
      LOG.info 'Waiting for 5 seconds...'
      sleep 5
      LOG.info 'Retry...'
      retry
    end
  end

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

  LOG.info 'Get Robot info'

  cmd = 'get_self'

  begin
    json = RedmineChatTelegram.run_cli_command(cmd, LOG)
    LOG.debug json
    robot_id = json['id']
  rescue NoMethodError => e
    LOG.error "TELEGRAM get_self #{e.class}: #{e.message} \n#{e.backtrace.join("\n")}"
    LOG.info 'May be problem with Telegram service. I will retry after 15 seconds'
    sleep 15
    retry
  end

  LOG.info 'Telegram Bot: Connecting to telegram...'
  bot      = Telegrammer::Bot.new(token)
  bot_name = bot.me.username

  plugin_settings = Setting.find_by(name: 'plugin_redmine_chat_telegram')

  plugin_settings_hash             = plugin_settings.value
  plugin_settings_hash['bot_name'] = "user##{bot.me.id}"
  plugin_settings_hash['bot_id']   = bot.me.id
  plugin_settings_hash['robot_id'] = robot_id
  plugin_settings.value            = plugin_settings_hash

  plugin_settings.save

  until bot_name.present?

    LOG.error 'Telegram Bot Token is invalid or Telegram API is in downtime. I will try again after minute'
    sleep 60

    LOG.info 'Telegram Bot: Connecting to telegram...'
    bot      = Telegrammer::Bot.new(token)
    bot_name = bot.me.username

  end

  LOG.info "#{bot_name}: connected"

  LOG.info 'Scheduling history update rake task...'

  Thread.new do
    sleep 5 * 60
    Rake::Task['chat_telegram:history_update'].invoke
  end

  LOG.info 'Task will start after 5 minutes'

  LOG.info "#{bot_name}: waiting for new messages in group chats..."
  bot
end

namespace :chat_telegram do
  task history_update: :environment do
    begin
      I18n.locale = Setting['default_language']

      RedmineChatTelegram::TelegramGroup.find_each do |telegram_group|
        issue = telegram_group.issue

        unless issue.closed?
          present_message_ids = issue.telegram_messages.pluck(:telegram_id)

          bot_ids = [Setting.plugin_redmine_chat_telegram['bot_id'].to_i,
                     Setting.plugin_redmine_chat_telegram['robot_id'].to_i]

          telegram_group = issue.telegram_group
          telegram_id    = telegram_group.telegram_id.abs

          RedmineChatTelegram::HISTORY_UPDATE_LOG.debug "chat##{telegram_id}"

          chat_name         = "chat##{telegram_id.abs}"
          page              = 0
          has_more_messages = RedmineChatTelegram.create_new_messages(issue.id, chat_name, bot_ids,
                                                                      present_message_ids, page)

          while has_more_messages
            page += 1
            has_more_messages = RedmineChatTelegram.create_new_messages(issue.id, chat_name, bot_ids,
                                                                        present_message_ids, page)
          end
        end
      end
    rescue ActiveRecord::RecordNotFound => e
      # ignore
    end
  end

  # bundle exec rake chat_telegram:bot PID_DIR='/tmp'
  desc "Runs telegram bot process (options: PID_DIR='/pid/dir')"
  task bot: :environment do
    LOG         = Rails.env.production? ? Logger.new(Rails.root.join('log/chat_telegram', 'bot.log')) : Logger.new(STDOUT)
    I18n.locale = Setting['default_language']

    begin
      bot = chat_telegram_bot_init
      bot.get_updates(fail_silently: false) do |command|
        next unless command.is_a?(Telegrammer::DataTypes::Message)
        RedmineChatTelegram::BotService.new(command, bot).call
      end
    rescue HTTPClient::ConnectTimeoutError, HTTPClient::KeepAliveDisconnected,
           Telegrammer::Errors::TimeoutError, Telegrammer::Errors::ServiceUnavailableError => e
      LOG.error "GLOBAL ERROR WITH RESTART #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}"
      LOG.info 'Restarting...'
      retry
    rescue Exception => e
      ExceptionNotifier.notify_exception(e) if defined?(ExceptionNotifier)
      LOG.error "GLOBAL #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}"
    end
  end
end
