def chat_telegram_bot_init
  token = Setting.plugin_redmine_chat_telegram['bot_token']

  unless token.present?
    LOG.error 'Telegram Bot Token not found. Please set it in the plugin config web-interface.'
    exit
  end

  LOG.info 'Get Robot info'

  result = RedmineChatTelegram::Telegram.new.execute('GetSelf')

  json = JSON.parse(result)

  robot_id = json['peer_id'] || json['id']

  LOG.info 'Telegram Bot: Connecting to telegram...'

  require 'telegram/bot'

  bot      = Telegram::Bot::Client.new(token)
  bot_info = bot.api.get_me["result"]
  bot_name = bot_info["username"]

  until bot_name.present?
    LOG.error 'Telegram Bot Token is invalid or Telegram API is in downtime. I will try again after minute'
    sleep 60

    LOG.info 'Telegram Bot: Connecting to telegram...'
    bot      = Telegram::Bot::Client.new(token)
    bot_info = bot.api.get_me["result"]
    bot_name = bot_info["username"]
  end

  plugin_settings = Setting.find_by(name: 'plugin_redmine_chat_telegram')

  plugin_settings_hash             = plugin_settings.value
  plugin_settings_hash['bot_name'] = bot_name
  plugin_settings_hash['bot_id']   = bot_info["id"]
  plugin_settings_hash['robot_id'] = robot_id
  plugin_settings.value            = plugin_settings_hash

  plugin_settings.save

  LOG.info "#{bot_name}: connected"

  bot
end

namespace :chat_telegram do
  # bundle exec rake chat_telegram:bot PID_DIR='/tmp'
  desc "Runs telegram bot process (options: PID_DIR='/pid/dir')"
  task bot: :environment do
    LOG = Rails.env.production? ? Logger.new(Rails.root.join('log/chat_telegram', 'bot.log')) : Logger.new(STDOUT)
    RedmineChatTelegram.set_locale

    chat_telegram_bot_init
  end
end
