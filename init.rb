require 'yaml'
REDMINE_CHAT_TELEGRAM_CONFIG = YAML.load_file(File.expand_path('../config/telegram.yml', __FILE__))

FileUtils.mkdir_p(Rails.root.join('log/chat_telegram')) unless Dir.exist?(Rails.root.join('log/chat_telegram'))

require 'redmine'
require_dependency 'redmine_chat_telegram'
require_dependency 'redmine_chat_telegram/hook_listener'
require_dependency 'redmine_chat_telegram/issue_patch'

Redmine::Plugin.register :redmine_chat_telegram do
  name 'Redmine Chat Telegram plugin'
  url 'https://github.com/centosadmin/redmine_chat_telegram'
  description 'This is a plugin for Redmine which adds Telegram Group Chat to Redmine Issue'
  version '0.5.0'
  author 'Centos-admin.ru'
  author_url 'http://centos-admin.ru'

  settings(default: {'bot_name' => 'BotName', 'bot_token' => 'bot_token'},
           partial: 'settings/chat_telegram')

  project_module :chat_telegram do
    permission :create_telegram_chat, :telegram_group_chats => :create
  end
end
