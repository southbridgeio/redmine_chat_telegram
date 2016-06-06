require 'yaml'
REDMINE_CHAT_TELEGRAM_CONFIG = YAML.load_file(File.expand_path('../config/telegram.yml', __FILE__))

FileUtils.mkdir_p(Rails.root.join('log/chat_telegram')) unless Dir.exist?(Rails.root.join('log/chat_telegram'))
TELEGRAM_CLI_LOG = Logger.new(Rails.root.join('log/chat_telegram', 'telegram-cli.log'))

require 'redmine_chat_telegram'

ActionDispatch::Callbacks.to_prepare do
  paths = '/lib/redmine_chat_telegram/{patches/*_patch,hooks/*_hook}.rb'
  Dir.glob(File.dirname(__FILE__) + paths).each do |file|
    require_dependency file
  end
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
  version '1.1.1.5'
  author 'Centos-admin.ru'
  author_url 'https://centos-admin.ru'

  settings(default: {
                      'bot_token'    => 'bot_token',
                      'daily_report' => '1'
                    },
           partial: 'settings/chat_telegram')

  project_module :chat_telegram do
    permission :create_telegram_chat, :telegram_group_chats => :create
    permission :close_telegram_chat, :telegram_group_chats => :destroy
    permission :view_telegram_chat_link, :telegram_group_chats => :create
    permission :view_telegram_chat_archive, :telegram_group_chats => :create
  end
end
