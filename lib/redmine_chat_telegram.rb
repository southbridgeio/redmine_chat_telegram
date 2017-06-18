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
    if Setting['protocol'] == 'https'
      URI::HTTPS.build(host: Setting['host_name'], path: "/issues/#{issue_id}").to_s
    else
      URI::HTTP.build(host: Setting['host_name'], path: "/issues/#{issue_id}").to_s
    end
  end

  def self.run_cli_command(command, args: nil, logger: nil)
    RedmineChatTelegram::Telegram.new.execute(command, args: args, config_path: REDMINE_CHAT_TELEGRAM_PHANTOMJS_CONFIG, logger: logger)
  end
end
