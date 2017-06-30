require 'timeout'
module RedmineChatTelegram
  def self.table_name_prefix
    'redmine_chat_telegram_'
  end

  def self.bot_token
    Setting.plugin_redmine_chat_telegram['bot_token']
  end

  def self.set_locale
    I18n.locale = Setting['default_language']
  end

  def self.issue_url(issue_id)
    url = Addressable::URI.parse("#{Setting['protocol']}://#{Setting['host_name']}/issues/#{issue_id}")
    url.to_s
  end

  def self.run_cli_command(command, args: nil)
    TelegramCommon::Telegram.new.execute(command, args: args)
  end

  def self.bot_initialize
    token = Setting.plugin_redmine_chat_telegram['bot_token']
    self_info = self.run_cli_command('GetSelf')

    if self_info.blank?
      fail 'Please, set correct settings for plugin TelegramCommon'
    end

    json = JSON.parse(self_info)
    robot_id = json['peer_id'] || json['id']

    bot      = Telegram::Bot::Client.new(token)
    bot_info = bot.api.get_me['result']
    bot_name = bot_info['username']

    until bot_name.present?
      sleep 60

      bot      = Telegram::Bot::Client.new(token)
      bot_info = bot.api.get_me['result']
      bot_name = bot_info['username']
    end

    plugin_settings = Setting.find_by(name: 'plugin_redmine_chat_telegram')

    plugin_settings_hash             = plugin_settings.value
    plugin_settings_hash['bot_name'] = bot_name
    plugin_settings_hash['bot_id']   = bot_info['id']
    plugin_settings_hash['robot_id'] = robot_id
    plugin_settings.value            = plugin_settings_hash

    plugin_settings.save

    bot
  end

  def self.handle_message(message)
    RedmineChatTelegram::Bot.new(message).call if message.is_a?(Telegram::Bot::Types::Message)

    group = RedmineChatTelegram::TelegramGroup.find_by(telegram_id: message.chat.id.abs)

    if group.present?
      sent_at = Time.at message.date

      from = message.from
      from_id = from.id
      from_first_name = from.first_name
      from_last_name = from.last_name
      from_username = from.username

      message_text = message.text

      TelegramMessage.where(telegram_id: message.message_id)
          .first_or_create! issue_id: group.issue.id,
                            sent_at: sent_at,
                            from_id: from_id,
                            from_first_name: from_first_name,
                            from_last_name: from_last_name,
                            from_username: from_username,
                            message: message_text
    end
  end
end
