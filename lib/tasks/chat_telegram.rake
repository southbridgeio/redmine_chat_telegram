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

  LOG.info "Get Robot info"

  cmd      = 'get_self'
  json     = RedmineChatTelegram.run_cli_command(cmd)
  robot_id = json['id']

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
  task :history_update => :environment do
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

          while has_more_messages do
            page              += 1
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
  task :bot => :environment do
    begin
      LOG         = Rails.env.production? ? Logger.new(Rails.root.join('log/chat_telegram', 'bot.log')) : Logger.new(STDOUT)
      I18n.locale = Setting['default_language']

      bot = chat_telegram_bot_init

      bot.get_updates(fail_silently: false) do |message|
        begin
          next unless message.is_a?(Telegrammer::DataTypes::Message) # Update for telegrammer gem 0.8.0

          telegram_chat_id = message.chat.id

          begin
            issue = Issue.joins(:telegram_group).find_by!(redmine_chat_telegram_telegram_groups:
                                                              { telegram_id: telegram_chat_id.abs })
          rescue Exception => e
            LOG.error "#{e.class}: #{e.message}\n#{e.backtrace.join("\n")}"
            next
          end

          telegram_id = message.message_id
          sent_at     = message.date

          from_id         = message.from.id
          from_first_name = message.from.first_name
          from_last_name  = message.from.last_name
          from_username   = message.from.username

          telegram_message = TelegramMessage.new issue_id:       issue.id,
                                                 telegram_id:    telegram_id,
                                                 sent_at:        sent_at,
                                                 from_id:        from_id, from_first_name: from_first_name,
                                                 from_last_name: from_last_name, from_username: from_username,
                                                 is_system:      true, bot_message: true
          if message.group_chat_created

            issue_url = RedmineChatTelegram.issue_url(issue.id)
            bot.send_message(chat_id:                  telegram_chat_id,
                             text:                     I18n.t('redmine_chat_telegram.messages.hello',
                                                              issue_url: issue_url),
                             disable_web_page_preview: true)

            telegram_message.message = 'chat_was_created'
            telegram_message.save
          else

            if message.new_chat_participant.present?
              new_chat_participant = message.new_chat_participant

              if message.from.id == new_chat_participant.id
                telegram_message.message = 'joined'
              else
                telegram_message.message     = 'invited'
                telegram_message.system_data = chat_user_full_name(new_chat_participant)
              end

              telegram_message.save

            elsif message.left_chat_participant.present?
              left_chat_participant = message.left_chat_participant

              if message.from.id == left_chat_participant.id
                telegram_message.message = 'left_group'
              else
                telegram_message.message_text = 'kicked'
                telegram_message.system_data  = chat_user_full_name(left_chat_participant)
              end

              telegram_message.save

            elsif message.text.present? and message.chat.type == 'group'
              issue_url = RedmineChatTelegram.issue_url(issue.id)

              message_text   = message.text
              issue_url_text = "#{issue.subject}\n#{issue_url}"

              if message_text.include?('/task') or message_text.include?('/link') or message_text.include?('/url')
                bot.send_message(chat_id:                  telegram_chat_id,
                                 text:                     issue_url_text,
                                 disable_web_page_preview: true)

                next unless message_text.gsub('/task', '').gsub('/link', '').gsub('/url', '').strip.present?

              end

              bot_message = (from_id == Setting.plugin_redmine_chat_telegram['bot_id'].to_i) or
                  (from_id == Setting.plugin_redmine_chat_telegram['robot_id'].to_i)

              telegram_message.message     = message_text
              telegram_message.bot_message = bot_message
              telegram_message.is_system   = false

              if message_text.include?('/log')
                telegram_message.message = message_text.gsub('/log', '')

                journal_text = telegram_message.as_text(with_time: false)
                issue.init_journal(User.anonymous,
                                   "_#{ I18n.t('redmine_chat_telegram.journal.from_telegram') }:_ \n\n#{journal_text}")
                issue.save
              end

              telegram_message.save!

            end
          end

        rescue ActiveRecord::RecordNotFound
          # ignore
        rescue Exception => e
          LOG.error "UPDATE #{e.class}: #{e.message} \n#{e.backtrace.join("\n")}"
          print e.backtrace.join("\n")
        end
      end
    rescue Exception => e
      LOG.error "GLOBAL #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}"
    end
  end
end
