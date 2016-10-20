resources :telegram_group_chats, only: [:create, :destroy]
get 'issues/:id/telegram_messages' => 'telegram_messages#index', as: 'issue_telegram_messages'
post 'issues/:id/telegram_messages/publish' => 'telegram_messages#publish', as: 'publish_issue_telegram_messages'

namespace :redmine_chat_telegram do
  get 'connect' => 'telegram_connections#create', as: 'connect'
end
