require File.expand_path('../../../../test_helper', __FILE__)

class RedmineChatTelegram::Commands::IssueChatCommandTest < ActiveSupport::TestCase
  fixtures :projects, :trackers, :issues, :users, :issue_statuses, :journals, :email_addresses, :enabled_modules

  let(:user) { User.find(1) }
  let(:issue) { Issue.find(1) }

  let(:command_params) do
    {
      chat: { id: 123, type: 'private' },
      message_id: 123_456,
      date: Date.today,
      from: { id: 998_899, first_name: 'Qw', last_name: 'Ert', username: 'qwert' }
    }
  end

  let(:chat) do
    issue.create_telegram_group(shared_url: 'http://telegram.me/chat', telegram_id: 123_456)
  end

  before do
    TelegramCommon::Account.create(user_id: user.id, telegram_id: 998_899)
  end

  describe '/chat' do
    it 'sends help' do
      RedmineChatTelegram::Commands::BaseBotCommand.any_instance
        .expects(:send_message)
        .with(I18n.t('redmine_chat_telegram.bot.chat.help'))

      command = Telegram::Bot::Types::Message.new(command_params.merge(text: '/chat'))
      RedmineChatTelegram::Commands::IssueChatCommand.new(command).execute
    end
  end

  describe '/chat info' do
    it 'sends link to chat if user has required rights' do
      User.any_instance.stubs(:allowed_to?).returns(true)
      chat
      text = 'http://telegram.me/chat'
      RedmineChatTelegram::Commands::BaseBotCommand.any_instance
        .expects(:send_message)
        .with(text)

      command = Telegram::Bot::Types::Message.new(command_params.merge(text: '/chat info 1'))
      RedmineChatTelegram::Commands::IssueChatCommand.new(command).execute
    end

    it "sends 'access denied' message if user hasn't required rights" do
      text = 'Access denied.'
      RedmineChatTelegram::Commands::BaseBotCommand.any_instance
        .expects(:send_message)
        .with(text)
      User.any_instance.stubs(:allowed_to?).returns(false)
      chat
      command = Telegram::Bot::Types::Message.new(command_params.merge(text: '/chat info 1'))
      RedmineChatTelegram::Commands::IssueChatCommand.new(command).execute
    end

    it "sends 'chat not found' message if chat not found" do
      text = 'Chat not found.'
      RedmineChatTelegram::Commands::BaseBotCommand.any_instance
        .expects(:send_message)
        .with(text)
      User.any_instance.stubs(:allowed_to?).returns(true)
      command = Telegram::Bot::Types::Message.new(command_params.merge(text: '/chat info 1'))
      RedmineChatTelegram::Commands::IssueChatCommand.new(command).execute
    end

    it "sends 'issue not found' message if issue not found" do
      issue.destroy
      text = 'Issue not found.'
      RedmineChatTelegram::Commands::BaseBotCommand.any_instance
        .expects(:send_message)
        .with(text)
      command = Telegram::Bot::Types::Message.new(command_params.merge(text: '/chat info 1'))
      RedmineChatTelegram::Commands::IssueChatCommand.new(command).execute
    end
  end

  describe '/chat create' do
    it 'creates chat if user has required rights and module is enabled' do
      EnabledModule.create(name: 'chat_telegram', project_id: 1)
      RedmineChatTelegram::Commands::BaseBotCommand.any_instance
        .expects(:send_message)
        .with('Creating chat. Please wait.')
      RedmineChatTelegram::Commands::BaseBotCommand.any_instance
        .expects(:send_message)
        .with('Chat was created. Join it here: http://telegram.me/chat')

      User.any_instance.stubs(:allowed_to?).returns(true)
      RedmineChatTelegram::GroupChatCreator.any_instance.stubs(:run)
      chat # GroupChatCreator creates chat, but here it's stubbed, so do it manually

      command = Telegram::Bot::Types::Message.new(command_params.merge(text: '/chat create 1'))
      RedmineChatTelegram::Commands::IssueChatCommand.new(command).execute
    end

    it "doesn't create chat is plugins module is disabled" do
      RedmineChatTelegram::Commands::BaseBotCommand.any_instance
        .expects(:send_message)
        .with('Telegam chat plugin for current project is disabled.')
      User.any_instance.stubs(:allowed_to?).returns(true)

      command = Telegram::Bot::Types::Message.new(command_params.merge(text: '/chat create 1'))
      RedmineChatTelegram::Commands::IssueChatCommand.new(command).execute
    end
  end

  describe '/chat close' do
    it 'closes chat if it exists and user has required rights' do
      RedmineChatTelegram::Commands::BaseBotCommand.any_instance
        .expects(:send_message)
        .with('Chat was successfully destroyed.')
      User.any_instance.stubs(:allowed_to?).returns(true)
      RedmineChatTelegram::GroupChatDestroyer.any_instance.stubs(:run)
      chat

      command = Telegram::Bot::Types::Message.new(command_params.merge(text: '/chat close 1'))
      RedmineChatTelegram::Commands::IssueChatCommand.new(command).execute
    end
  end
end
