resources :telegram_group_chats, only: [:create, :destroy]
get 'issues/:id/telegram_messages' => 'telegram_messages#index', as: 'issue_telegram_messages'
post 'issues/:id/telegram_messages/publish' => 'telegram_messages#publish', as: 'publish_issue_telegram_messages'
get 'telegram_connect' => 'redmine_telegram_connections#create', as: 'redmine_chat_telegram_connect'
