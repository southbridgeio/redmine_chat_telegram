class TelegramSetupController < ApplicationController
  unloadable

  layout false

  def bot_init
    web_hook_url = "https://#{Setting.host_name}/redmine_chat_telegram/api/web_hook"

    bot = RedmineChatTelegram.bot_initialize
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
