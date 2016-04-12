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
    "#{cli_path} -WCD --json -k  #{public_key_path} -e "
  end

  def self.run_cli_command(cmd, logger = nil)
    logger.debug cmd if logger

    cmd_as_param = cmd.gsub("\"", "\\\"")

    result = %x( #{cli_base} "#{cmd_as_param}" )
    logger.debug result if logger

    JSON.parse(result.scan(/{.+}/).first)
  end
end
