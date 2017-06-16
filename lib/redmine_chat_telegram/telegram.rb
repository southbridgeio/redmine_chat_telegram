module RedmineChatTelegram
  class Telegram
    include Rails.application.routes.url_helpers

    def execute(command, args: {})
      @command = command
      @args = args

      make_request
      fail response[1] if response[0] == 'failed'

      response[1]
    end

    private

    attr_reader :command, :args, :api_result

    def make_request
      phantom =  Setting.plugin_redmine_chat_telegram['phantomjs_path']
      api_url = "#{Setting.protocol}://#{Setting.host_name}/plugin_assets/redmine_chat_telegram/webogram/index.html"
      params = {
        command: command,
        args: args.to_json
      }
      full_url = "#{api_url}#/api?#{params.to_query}"
      cmd = "#{phantom} #{REDMINE_CHAT_TELEGRAM_PHANTOMJS_FILE} \"#{full_url}\""
      @api_result = `#{cmd}`
    end

    def response
      api_result.scan(/(success|failed): (.*)/).flatten
    end
  end
end
