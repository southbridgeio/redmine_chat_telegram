class TelegramApiController < ApplicationController
  unloadable

  skip_before_filter :check_if_login_required, only: [:web_hook]

  layout false

  def web_hook
    logger.tagged('web_hook') { logger.info params.to_json }
    render json: params
  end

  def bot_init
    web_hook_url = "https://#{Setting.host_name}/redmine_chat_telegram/api/web_hook"
    token = Setting.plugin_redmine_chat_telegram['bot_token']
    bot   = Telegram::Bot::Client.new(token)
    bot.api.setWebhook(url: web_hook_url)
    redirect_to plugin_settings_path('redmine_chat_telegram'), notice: t('redmine_chat_telegram.authorize.success')
  end

  def bot_deinit
    token = Setting.plugin_redmine_chat_telegram['bot_token']
    bot   = Telegram::Bot::Client.new(token)
    bot.api.setWebhook(url: '')
    redirect_to plugin_settings_path('redmine_chat_telegram'), notice: t('redmine_chat_telegram.authorize.success')
  end

  def authorize
    result = telegram.execute('Login',
      args: {
        phone_number: Setting.plugin_redmine_chat_telegram['telegram_phone_number'],
        phone_code_hash: Setting.plugin_redmine_chat_telegram['telegram_phone_code_hash'],
        phone_code: Setting.plugin_redmine_chat_telegram['telegram_phone_code']
      }
    )

    telegram_auth_step = Setting.plugin_redmine_chat_telegram['telegram_auth_step'].to_i

    if telegram_auth_step == 0
      phone_code_hash = JSON.parse(result)['phone_code_hash']

      fail if phone_code_hash.blank?

      Setting.plugin_redmine_chat_telegram['telegram_phone_code_hash'] = phone_code_hash
      Setting.plugin_redmine_chat_telegram['telegram_auth_step'] = 1
    elsif telegram_auth_step == 1
      reset_telegram_auth_step
    else
      fail("Undefined telegram auth step: #{telegram_auth_step}")
    end

    redirect_to plugin_settings_path('redmine_chat_telegram'), notice: t('redmine_chat_telegram.authorize.success')
  rescue => e
    logger.fatal 'Failed to process API request'
    logger.fatal e.to_s
    logger.fatal result
    return redirect_to plugin_settings_path('redmine_chat_telegram'), notice: t('redmine_chat_telegram.authorize.failed')
  end

  def auth_status
    telegram.execute( 'IsLogged')
    redirect_to plugin_settings_path('redmine_chat_telegram'), notice: t('redmine_chat_telegram.authorized')
  rescue
    redirect_to plugin_settings_path('redmine_chat_telegram'), alert: t('redmine_chat_telegram.not_authorized')
  end

  def deauthorize
    telegram.execute( 'Logout')
    redirect_to plugin_settings_path('redmine_chat_telegram'), notice: t('redmine_chat_telegram.authorize.success')
  rescue
    redirect_to plugin_settings_path('redmine_chat_telegram'), alert: t('redmine_chat_telegram.authorize.failed')
  end

  private

  def reset_telegram_auth_step
    Setting.plugin_redmine_chat_telegram['telegram_auth_step'] = 0
    Setting.plugin_redmine_chat_telegram['telegram_phone_code'] = nil
    Setting.plugin_redmine_chat_telegram['telegram_phone_code_hash'] = nil
  end

  def telegram
    @telegram ||= RedmineChatTelegram::Telegram.new
  end
end
