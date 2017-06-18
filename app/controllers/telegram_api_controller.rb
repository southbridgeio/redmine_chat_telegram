class TelegramApiController < ApplicationController
  unloadable

  skip_before_filter :check_if_login_required, only: [:web_hook]
  skip_before_action :verify_authenticity_token, only: [:web_hook]

  layout false

  def web_hook
    message = Telegram::Bot::Types::Update.new(params).message
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

    head :ok, content_type: 'text/html'
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
    result = telegram.execute( 'IsLogged')
    if result == 'true'
      redirect_to plugin_settings_path('redmine_chat_telegram'), notice: t('redmine_chat_telegram.authorized')
    else
      redirect_to plugin_settings_path('redmine_chat_telegram'), alert: t('redmine_chat_telegram.not_authorized')
    end
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
