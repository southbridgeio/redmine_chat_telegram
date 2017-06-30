resources :telegram_group_chats, only: [:create, :destroy]
get 'issues/:id/telegram_messages' => 'telegram_messages#index', as: 'issue_telegram_messages'
post 'issues/:id/telegram_messages/publish' => 'telegram_messages#publish', as: 'publish_issue_telegram_messages'

scope :redmine_chat_telegram do
  scope :api do
    post 'web_hook', to: TelegramHandlerController.action(:handle), as: 'chat_telegram_api_webhook'
    post 'bot_init' => 'telegram_setup#bot_init', as: 'chat_telegram_api_bot_init'
    delete 'bot_deinit' => 'telegram_setup#bot_deinit', as: 'chat_telegram_api_bot_deinit'
  end
end
