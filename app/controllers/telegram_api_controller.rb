class TelegramApiController < ApplicationController
  unloadable

  skip_before_filter :check_if_login_required, only: [:web_hook]
  skip_before_action :verify_authenticity_token, only: [:web_hook]

  layout false

  def web_hook
    message = Telegram::Bot::Types::Update.new(params).message

    if message.present?
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
            .first_or_create issue_id: group.issue.id,
                             sent_at: sent_at,
                             from_id: from_id,
                             from_first_name: from_first_name,
                             from_last_name: from_last_name,
                             from_username: from_username,
                             message: message_text
      end
    else
      logger.fatal "Can't find message"
      logger.fatal params.to_json
    end

    head :ok, content_type: 'text/html'
  end

  def bot_init
    token = Setting.plugin_redmine_chat_telegram['bot_token']
    web_hook_url = "https://#{Setting.host_name}/redmine_chat_telegram/api/web_hook"

    self_info = RedmineChatTelegram.run_cli_command('GetSelf')
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

    bot.api.setWebhook(url: web_hook_url)

    redirect_to plugin_settings_path('redmine_chat_telegram'), notice: t('redmine_chat_telegram.bot.authorize.success')
  end

  def bot_deinit
    token = Setting.plugin_redmine_chat_telegram['bot_token']
    bot   = Telegram::Bot::Client.new(token)
    bot.api.setWebhook(url: '')
    redirect_to plugin_settings_path('redmine_chat_telegram'), notice: t('redmine_chat_telegram.bot.deauthorize.success')
  end
end
