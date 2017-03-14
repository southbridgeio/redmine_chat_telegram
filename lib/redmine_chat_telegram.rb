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

  def self.cli_base
    cli_path = REDMINE_CHAT_TELEGRAM_CONFIG['telegram_cli_path']
    public_key_path = REDMINE_CHAT_TELEGRAM_CONFIG['telegram_cli_public_key_path']
    "#{cli_path} -WCD -v --json -k  #{public_key_path} -e "
  end

  def self.mode
    REDMINE_CHAT_TELEGRAM_CONFIG['telegram_cli_mode'].to_i
  end

  def self.run_cli_command(cmd, logger = nil)
    logger.debug cmd if logger

    cmd_as_param = cmd.gsub('"', '\\"')

    logger.debug %( #{cli_base} "#{cmd_as_param}" ) if logger

    result = ` #{cli_base} "#{cmd_as_param}" `

    logger.debug result if logger

    json_string = result.scan(/\[?{.+}\]?/).first
    JSON.parse(json_string) if json_string.present?
  end

  def self.socket_cli_command(cmd, logger = nil)
    logger.debug cmd if logger
    socket = TCPSocket.open('127.0.0.1', 2391)
    socket.puts cmd
    socket.flush

    answer = socket.readline
    length = answer.match(/ANSWER (\d+)/)[1].to_i

    result = socket.read(length)
    logger.debug result if logger

    JSON.parse result

  rescue
    puts $ERROR_INFO
  ensure
    socket.close if socket
  end

  CHAT_HISTORY_PAGE_SIZE = 100
  HISTORY_UPDATE_LOG = Logger.new(Rails.root.join('log/chat_telegram',
    'telegram-group-history-update.log'))

  def self.create_new_messages(issue_id, chat_name, bot_ids, present_message_ids, page)
    cmd = "history #{chat_name} #{CHAT_HISTORY_PAGE_SIZE} #{CHAT_HISTORY_PAGE_SIZE * page}"

    json_messages = RedmineChatTelegram.socket_cli_command(cmd, HISTORY_UPDATE_LOG)

    if json_messages.present?

      new_json_messages = json_messages.select do |message|
        from = message['from']

        if from.present?

          peer_id = from['peer_id'] || from['id']


          !present_message_ids.include?(message['id']) &&
            !bot_ids.include?(peer_id)
        end
      end

      new_json_messages.each do |message|
        message_id = message['id']
        sent_at = Time.at message['date']

        from = message['from']
        from_id = from['id']
        from_first_name = from['first_name']
        from_last_name = from['last_name']
        from_username = from['username']

        message_text = message['text']
        TelegramMessage.where(telegram_id: message_id)
          .first_or_create issue_id: issue_id,
            sent_at: sent_at,
            from_id: from_id,
            from_first_name: from_first_name,
            from_last_name: from_last_name,
            from_username: from_username,
            message: message_text
      end
      json_messages.size == CHAT_HISTORY_PAGE_SIZE
    else
      false
    end
  end
end
