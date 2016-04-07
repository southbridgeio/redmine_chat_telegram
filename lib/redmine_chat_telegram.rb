module RedmineChatTelegram
  def self.table_name_prefix
    'redmine_chat_telegram_'
  end

  def self.issue_url(issue_id)
    if Setting['protocol'] == 'https'
      URI::HTTPS.build({ host: Setting['host_name'], path: "/issues/#{issue_id}" }).to_s
    else
      URI::HTTP.build({ host: Setting['host_name'], path: "/issues/#{issue_id}" }).to_s
    end
  end

  def self.cli_base
    cli_path        = REDMINE_CHAT_TELEGRAM_CONFIG['telegram_cli_path']
    public_key_path = REDMINE_CHAT_TELEGRAM_CONFIG['telegram_cli_public_key_path']
    "#{cli_path} -WCI -k  #{public_key_path} -e "
  end
end
