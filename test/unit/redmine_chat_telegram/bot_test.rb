require File.expand_path('../../../test_helper', __FILE__)
require 'minitest/mock'
require 'minitest/autorun'

class RedmineChatTelegram::BotTest < ActiveSupport::TestCase
  fixtures :projects, :trackers, :issues, :users, :email_addresses

  let(:bot) { Minitest::Mock.new.expect(:present?, true) }
  let(:issue) { Issue.find(1) }
  let(:user) { User.find(1) }

  let(:command_params) do
    {
      chat: { id: 123, type: 'group' },
      message_id: 123_456,
      date: Date.today.to_time.to_i,
      from: { id: 998_899, first_name: 'Qw', last_name: 'Ert', username: 'qwert' }
    }
  end

  before do
    RedmineChatTelegram::TelegramGroup.create(telegram_id: 123, issue_id: 1)
    TelegramCommon::Account.create(user_id: user.id, telegram_id: 998_899)
  end

  describe 'new_chat_created' do
    let(:command) do
      Telegram::Bot::Types::Message
        .new(command_params.merge(group_chat_created: true))
    end

    it 'sends message to chat save telegram message' do
      RedmineChatTelegram.stub :issue_url, 'http://site.com/issue/1' do
        RedmineChatTelegram::Bot.any_instance
          .expects(:send_message)
          .with('Hello, everybody! This is a chat for issue: http://site.com/issue/1')

        RedmineChatTelegram::Bot.new(command).call

        message = TelegramMessage.last
        assert_equal message.message, 'chat_was_created'
        assert_equal message.is_system, true
      end
    end
  end

  describe 'new_chat_member' do
    it 'creates joined system message when user joined' do
      command = Telegram::Bot::Types::Message
        .new(command_params.merge(new_chat_member: { id: 998_899 }))
      RedmineChatTelegram::Bot.new(command).call

      message = TelegramMessage.last
      assert_equal message.message, 'joined'
      assert_equal message.is_system, true
    end

    it 'creates invited system message when user was invited' do
      command = Telegram::Bot::Types::Message
        .new(command_params.merge(new_chat_member: { id: 7777 }))
      RedmineChatTelegram::Bot.new(command).call

      message = TelegramMessage.last
      assert_equal message.message, 'invited'
      assert_equal message.is_system, true
    end
  end

  describe 'left_chat_member' do
    it 'creates left_group system message when user left group' do
      command = Telegram::Bot::Types::Message
                .new(command_params.merge(left_chat_member: { id: 998_899 }))
      RedmineChatTelegram::Bot.new(command).call

      message = TelegramMessage.last
      assert_equal message.message, 'left_group'
      assert_equal message.is_system, true
    end

    it 'creates kicked system message when user was kicked' do
      command = Telegram::Bot::Types::Message
                .new(command_params.merge(left_chat_member:
                                            { id: 8888,
                                              first_name: 'As',
                                              last_name: 'Dfg' }))
      RedmineChatTelegram::Bot.new(command).call

      message = TelegramMessage.last
      assert_equal message.message, 'kicked'
      assert_equal message.is_system, true
      assert_equal message.system_data, 'As Dfg'
    end
  end

  describe 'send current value for command without argument' do
    ['project','subject','status','tracker','priority','assigned_to','start_date','done_ratio'].each do |com|
      it "command /#{com}" do
        command = Telegram::Bot::Types::Message.new(command_params.merge(text: "/#{com}"))
        text = "#{com.capitalize}: #{issue.send(com).to_s}"
        RedmineChatTelegram::Bot.any_instance
          .expects(:send_message)
          .with(text)
        RedmineChatTelegram::Bot.new(command).call
      end
    end
  end

  describe 'send_issue_link' do
    it 'sends issue link with title if user has required rights' do
      User.any_instance.stubs(:allowed_to?).returns(true)
      RedmineChatTelegram.stub :issue_url, 'http://site.com/issue/1' do
        command = Telegram::Bot::Types::Message
                  .new(command_params.merge(text: '/link'))

        RedmineChatTelegram::Bot.any_instance
          .expects(:send_message)
          .with("<a href='http://site.com/issue/1'>##{issue.id}</a> <b>Cannot print recipes</b>\nPriority: #{issue.priority}\nStatus: #{issue.status}")

        RedmineChatTelegram::Bot.new(command).call
      end
    end

    it 'sends access denied if user has not access to issue' do
      User.any_instance.stubs(:allowed_to?).returns(false)
      RedmineChatTelegram.stub :issue_url, 'http://site.com/issue/1' do
        RedmineChatTelegram::Bot.any_instance
          .expects(:send_message)
          .with('Access denied.')

        command = Telegram::Bot::Types::Message.new(command_params.merge(text: '/link'))
        RedmineChatTelegram::Bot.new(command).call
      end
    end
  end

  describe 'log_message' do
    let(:command) do
      Telegram::Bot::Types::Message.new(command_params.merge(text: '/log this is text'))
    end

    it 'creates comment for issue' do
      User.any_instance.stubs(:allowed_to?).returns(true)
      RedmineChatTelegram::Bot.new(command).call
      assert_equal issue.journals.last.notes, "_from Telegram:_ \n\nQw Ert: this is text"
    end

    it 'creates message' do
      User.any_instance.stubs(:allowed_to?).returns(true)
      RedmineChatTelegram::Bot.new(command).call
      message = TelegramMessage.last
      assert_equal message.message, 'this is text'
      assert_equal message.bot_message, false
      assert_equal message.is_system, false
    end

    it 'sends access denied if user has not access to issue' do
      RedmineChatTelegram::Bot.any_instance
        .expects(:send_message)
        .with('Access denied.')
      User.any_instance.stubs(:allowed_to?).returns(false)
      RedmineChatTelegram::Bot.new(command).call
    end
  end

  describe 'save_message' do
    it 'creates message' do
      command = Telegram::Bot::Types::Message
                .new(command_params.merge(text: 'message from telegram'))
      RedmineChatTelegram::Bot.new(command).call
      message = TelegramMessage.last
      assert_equal message.message, 'message from telegram'
      assert_equal message.bot_message, false
      assert_equal message.is_system, false
    end
  end

  describe 'new' do
    it 'exucutes new_isssue command' do
      command = Telegram::Bot::Types::Message
                .new(command_params.merge(
                       text: '/new',
                       chat: { id: 123, type: 'private' }))

      RedmineChatTelegram::Commands::NewIssueCommand.any_instance.expects(:execute)

      RedmineChatTelegram::Bot.new(command).call
    end
  end
end
