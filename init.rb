require 'yaml'

FileUtils.mkdir_p(Rails.root.join('log/chat_telegram')) unless Dir.exist?(Rails.root.join('log/chat_telegram'))

Rails.application.config.eager_load_paths += Dir.glob("#{Rails.application.config.root}/plugins/redmine_chat_telegram/{lib,app/workers,app/models,app/controllers}")

require 'pluralization'
require 'redmine_chat_telegram'
require 'telegram/bot'

# Rails 5.1/Rails 4
reloader = defined?(ActiveSupport::Reloader) ? ActiveSupport::Reloader : ActionDispatch::Reloader

reloader.to_prepare do
  paths = '/lib/redmine_chat_telegram/{patches/*_patch,hooks/*_hook}.rb'
  Dir.glob(File.dirname(__FILE__) + paths).each do |file|
    require_dependency file
  end

  require_dependency 'telegram_common'
  TelegramCommon.update_manager.add_handler(->(message) { RedmineChatTelegram.handle_message(message) } )
end

Sidekiq::Logging.logger = Logger.new(Rails.root.join('log', 'sidekiq.log'))

Sidekiq::Cron::Job.create(name:  'Telegram Group Auto Close - every 1 hour',
                          cron:  '7 * * * *',
                          class: 'TelegramGroupAutoCloseWorker')

Sidekiq::Cron::Job.create(name:  'Telegram Group Daily Report - every day',
                          cron:  '7 0 * * *',
                          class: 'TelegramGroupDailyReportCronWorker')

Redmine::Plugin.register :redmine_chat_telegram do
  name 'Redmine Chat Telegram plugin'
  url 'https://github.com/centosadmin/redmine_chat_telegram'
  description 'This is a plugin for Redmine which adds Telegram Group Chat to Redmine Issue'
  version '2.1.0'
  author 'Southbridge'
  author_url 'https://github.com/centosadmin'

  settings(default: {
             'bot_token' => 'bot_token',
             'daily_report' => '1'
           },
           partial: 'settings/chat_telegram')

  project_module :chat_telegram do
    permission :create_telegram_chat,       telegram_group_chats: :create
    permission :close_telegram_chat,        telegram_group_chats: :destroy
    permission :view_telegram_chat_link,    telegram_group_chats: :create
    permission :view_telegram_chat_archive, telegram_group_chats: :create
    permission :manage_telegram_chat,       telegram_group_chats: :edit
  end
end
