require File.expand_path('../../../../test_helper', __FILE__)
require 'minitest/mock'
require 'minitest/autorun'

class RedmineChatTelegram::Commands::IssueChatCommandTest < ActiveSupport::TestCase
  fixtures :projects, :trackers, :issues, :users, :issue_statuses, :journals, :email_addresses, :enabled_modules

  let(:bot) { Minitest::Mock.new }
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
    I18n.locale = 'en'
    TelegramCommon::Account.create(user_id: user.id, telegram_id: 998_899)
  end

  describe '/chat' do
    it 'sends help' do
      bot.expect(:send_message, nil, [{ chat_id: 123,
                                        text: I18n.t('redmine_chat_telegram.bot.chat.help'),
                                        parse_mode: 'HTML' }])

      command = Telegrammer::DataTypes::Message.new(command_params.merge(text: '/chat'))
      RedmineChatTelegram::Commands::IssueChatCommand.new(command, bot).execute
      bot.verify
    end
  end

  describe '/chat info' do
    it 'sends link to chat if user has required rights' do
      User.any_instance.stubs(:allowed_to?).returns(true)
      chat
      bot.expect(:send_message, nil, [{ chat_id: 123,
                                        text: 'http://telegram.me/chat',
                                        parse_mode: 'HTML' }])
      command = Telegrammer::DataTypes::Message.new(command_params.merge(text: '/chat info 1'))
      RedmineChatTelegram::Commands::IssueChatCommand.new(command, bot).execute
      bot.verify
    end

    it "sends 'access denied' message if user hasn't required rights" do
      bot.expect(:send_message, nil, [{ chat_id: 123, text: 'Access denied.', parse_mode: 'HTML' }])
      User.any_instance.stubs(:allowed_to?).returns(false)
      chat
      command = Telegrammer::DataTypes::Message.new(command_params.merge(text: '/chat info 1'))
      RedmineChatTelegram::Commands::IssueChatCommand.new(command, bot).execute
      bot.verify
    end

    it "sends 'chat not found' message if chat not found" do
      bot.expect(:send_message, nil, [{ chat_id: 123, text: 'Chat not found.', parse_mode: 'HTML' }])
      User.any_instance.stubs(:allowed_to?).returns(true)
      command = Telegrammer::DataTypes::Message.new(command_params.merge(text: '/chat info 1'))
      RedmineChatTelegram::Commands::IssueChatCommand.new(command, bot).execute
      bot.verify
    end

    it "sends 'issue not found' message if issue not found" do
      issue.destroy
      bot.expect(:send_message, nil, [{ chat_id: 123, text: 'Issue not found.', parse_mode: 'HTML' }])
      command = Telegrammer::DataTypes::Message.new(command_params.merge(text: '/chat info 1'))
      RedmineChatTelegram::Commands::IssueChatCommand.new(command, bot).execute
      bot.verify
    end
  end

  describe '/chat create' do
    it 'creates chat if user has required rights and module is enabled' do
      EnabledModule.create(name: 'chat_telegram', project_id: 1)
      bot.expect(:send_message, nil, [{ chat_id: 123, text: 'Creating chat. Please wait.', parse_mode: 'HTML' }])
      bot.expect(:send_message, nil,
                 [{ chat_id: 123, text: 'Chat was created. Join it here: http://telegram.me/chat',
                    parse_mode: 'HTML' }])
      User.any_instance.stubs(:allowed_to?).returns(true)
      RedmineChatTelegram::GroupChatCreator.any_instance.stubs(:run)
      chat # GroupChatCreator creates chat, but here it's stubbed, so do it manually

      command = Telegrammer::DataTypes::Message.new(command_params.merge(text: '/chat create 1'))
      RedmineChatTelegram::Commands::IssueChatCommand.new(command, bot).execute
      bot.verify
    end

    it "doesn't create chat is plugins module is disabled" do
      bot.expect(:send_message, nil,
                 [{ chat_id: 123, text: 'Telegam chat plugin for current project is disabled.', parse_mode: 'HTML' }])
      User.any_instance.stubs(:allowed_to?).returns(true)

      command = Telegrammer::DataTypes::Message.new(command_params.merge(text: '/chat create 1'))
      RedmineChatTelegram::Commands::IssueChatCommand.new(command, bot).execute
      bot.verify
    end
  end

  describe '/chat close' do
    it 'closes chat if it exists and user has required rights' do
      bot.expect(:send_message, nil,
                 [{ chat_id: 123, text: 'Chat was successfully destroyed.', parse_mode: 'HTML' }])
      User.any_instance.stubs(:allowed_to?).returns(true)
      RedmineChatTelegram::GroupChatDestroyer.any_instance.stubs(:run)
      chat

      command = Telegrammer::DataTypes::Message.new(command_params.merge(text: '/chat close 1'))
      RedmineChatTelegram::Commands::IssueChatCommand.new(command, bot).execute
      bot.verify
    end
  end
end
