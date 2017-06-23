class TelegramSetupController < ApplicationController
  unloadable

  layout false

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
