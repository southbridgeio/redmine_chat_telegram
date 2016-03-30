require 'yaml'
REDMINE_CHAT_TELEGRAM_CONFIG = YAML.load_file(File.expand_path('../config/telegram.yml', __FILE__))

FileUtils.mkdir_p(Rails.root.join('log/chat_telegram')) unless Dir.exist?(Rails.root.join('log/chat_telegram'))

require 'redmine_chat_telegram'

ActionDispatch::Callbacks.to_prepare do
  paths = '/lib/redmine_chat_telegram/{patches/*_patch,hooks/*_hook}.rb'
  Dir.glob(File.dirname(__FILE__) + paths).each do |file|
    require_dependency file
  end
end

Redmine::Plugin.register :redmine_chat_telegram do
  name 'Redmine Chat Telegram plugin'
  url 'https://github.com/centosadmin/redmine_chat_telegram'
  description 'This is a plugin for Redmine which adds Telegram Group Chat to Redmine Issue'
  version '0.8.2'
  author 'Centos-admin.ru'
  author_url 'http://centos-admin.ru'

  settings(default: { 'bot_name' => 'BotName', 'bot_token' => 'bot_token' },
           partial: 'settings/chat_telegram')

  project_module :chat_telegram do
    permission :create_telegram_chat, :telegram_group_chats => :create
    permission :close_telegram_chat, :telegram_group_chats => :create
    permission :view_telegram_chat_link, :telegram_group_chats => :create
    permission :view_telegram_chat_archive, :telegram_group_chats => :create
  end
end
