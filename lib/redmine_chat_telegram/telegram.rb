module RedmineChatTelegram
  class Telegram
    def execute(command, config_path:, logger: nil, args: {})
      @command     = command
      @args        = args
      @logger      = logger
      @config_path = config_path

      debug(command)
      debug(args)

      make_request
      fail response[1] if response[0] == 'failed'

      response[1]
    end

    private

    attr_reader :command, :args, :config_path, :logger, :api_result

    def make_request
      @api_result = `#{cli_command}`
      debug(api_result)
      api_result
    end

    def cli_command
      cmd = "#{phantomjs} #{config_path} \"#{api_url}\""
      debug(cmd)
      cmd
    end

    def phantomjs
      Setting.plugin_redmine_chat_telegram['phantomjs_path']
    end

    def api_url
      params = {
        command: command,
        args: args.to_json
      }
      base_api = "#{Setting.protocol}://#{Setting.host_name}/plugin_assets/redmine_telegram_common/webogram/index.html"
      "#{base_api}#/api?#{params.to_query}"
    end

    def debug(message)
      log(message)
    end

    def log(message, operation: 'debug')
      if logger && message
        logger.public_send(operation, message)
      end
    end

    def response
      api_result.scan(/(success|failed): (.*)/).flatten
    end
  end
end
