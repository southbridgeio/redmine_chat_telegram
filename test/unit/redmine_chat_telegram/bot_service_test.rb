require File.expand_path('../../../test_helper', __FILE__)
require 'minitest/mock'
require 'minitest/autorun'

class RedmineChatTelegram::BotServiceTest < ActiveSupport::TestCase
  fixtures :projects, :trackers, :issues, :users, :email_addresses

  let(:bot) { Minitest::Mock.new.expect(:present?, true) }
  let(:issue) { Issue.find(1) }
  let(:user) { User.find(1) }

  let(:command_params) do
    {
      chat: { id: 123, type: 'group' },
      message_id: 123456,
      date: Date.today,
      from: { id: 998899, first_name: "Qw", last_name: "Ert", username: "qwert"}
    }
  end

  before do
    RedmineChatTelegram::TelegramGroup.create(
      telegram_id: 123,
      issue_id: 1)
  end

  describe "new_chat_created" do
    let(:command) do
      Telegrammer::DataTypes::Message
        .new(command_params.merge(group_chat_created: true))
    end

    it "sends message to chat save telegram message" do
      RedmineChatTelegram.stub :issue_url, "http://site.com/issue/1" do
        bot.expect(:send_message,
                   nil,
                   [{chat_id: command.chat.id,
                     text: "Hello, everybody! This is a chat for issue: http://site.com/issue/1",
                     disable_web_page_preview: true}])
        RedmineChatTelegram::BotService.new(command, bot).call

        message = TelegramMessage.last
        assert_equal message.message, 'chat_was_created'
        assert_equal message.is_system, true
        bot.verify
      end
    end
  end

  describe "new_chat_participant" do

    it "creates joined system message when user joined" do
      command = Telegrammer::DataTypes::Message
        .new(command_params.merge(new_chat_participant: { id: 998899 }))
      RedmineChatTelegram::BotService.new(command, bot).call

      message = TelegramMessage.last
      assert_equal message.message, 'joined'
      assert_equal message.is_system, true
    end

    it "creates invited system message when user was invited" do
      command = Telegrammer::DataTypes::Message
        .new(command_params.merge(new_chat_participant: { id: 7777 }))
      RedmineChatTelegram::BotService.new(command, bot).call

      message = TelegramMessage.last
      assert_equal message.message, 'invited'
      assert_equal message.is_system, true
    end
  end

  describe "left_chat_participant" do

    it "creates left_group system message when user left group" do
      command = Telegrammer::DataTypes::Message
                .new(command_params.merge(left_chat_participant: { id: 998899 }))
      RedmineChatTelegram::BotService.new(command, bot).call

      message = TelegramMessage.last
      assert_equal message.message, 'left_group'
      assert_equal message.is_system, true
    end

    it "creates kicked system message when user was kicked" do
      command = Telegrammer::DataTypes::Message
                .new(command_params.merge(left_chat_participant:
                                            { id: 8888,
                                              first_name: "As",
                                              last_name: "Dfg"}))
      RedmineChatTelegram::BotService.new(command, bot).call

      message = TelegramMessage.last
      assert_equal message.message, 'kicked'
      assert_equal message.is_system, true
      assert_equal message.system_data, 'As Dfg'
    end
  end

  describe "send_issue_link" do
    it "sends issue link with title" do
      RedmineChatTelegram.stub :issue_url, "http://site.com/issue/1" do
        command = Telegrammer::DataTypes::Message
                  .new(command_params.merge(text: "/link"))

        bot.expect(:send_message,
                   nil,
                   [{chat_id: command.chat.id,
                     text: "#{ issue.subject}\nhttp://site.com/issue/1",
                     disable_web_page_preview: true}])
        RedmineChatTelegram::BotService.new(command, bot).call

        bot.verify
      end
    end
  end

  describe "log_message" do
    before do
      command = Telegrammer::DataTypes::Message
                .new(command_params.merge(text: "/log this is text"))
      RedmineChatTelegram::BotService.new(command, bot).call
    end

    it "creates comment for issue" do
      assert_equal issue.journals.last.notes, "_from Telegram:_ \n\nQw Ert: this is text"
    end

    it "creates message" do
      message = TelegramMessage.last
      assert_equal message.message, 'this is text'
      assert_equal message.bot_message, false
      assert_equal message.is_system, false
    end
  end

  describe "save_message" do

    it "creates message" do
      command = Telegrammer::DataTypes::Message
                .new(command_params.merge(text: "message from telegram"))
      RedmineChatTelegram::BotService.new(command, bot).call
      message = TelegramMessage.last
      assert_equal message.message, 'message from telegram'
      assert_equal message.bot_message, false
      assert_equal message.is_system, false
    end
  end

  describe "connect" do

    it "sends what user not found if user not found" do
      bot.expect(:send_message, nil, [{chat_id: 123, text: 'User not found'}])

      command = Telegrammer::DataTypes::Message
                .new(command_params.merge(text: "/connect not-exist@mail.com",
                                          chat: { id: 123, type: 'private' }))
      RedmineChatTelegram::BotService.new(command, bot).call

      bot.verify
    end

    it "sends what user already connected if user already connected" do
      bot.expect(:send_message, nil, [{chat_id: 123, text: 'Your accounts already connected'}])

      command = Telegrammer::DataTypes::Message
                .new(command_params.merge(
                      text: "/connect #{ user.email_address.address }",
                      chat: { id: 123, type: 'private' }))

      ::TelegramCommon::Account.create(
        telegram_id: command.from.id,
        user_id: user.id)

      RedmineChatTelegram::BotService.new(command, bot).call

      bot.verify
    end

    it "sends message with success if user found and not connected" do
      bot.expect(:send_message, nil, [{chat_id: 123, text: "We sent email to address \"#{ user.email_address.address }\". Please follow instructions from it."}])

      RedmineChatTelegram::Mailer.expects(:telegram_connect)
        .returns(Minitest::Mock.new.expect(:deliver, nil))

      command = Telegrammer::DataTypes::Message
                .new(command_params.merge(
                      text: "/connect #{ user.email_address.address }",
                      chat: { id: 123, type: 'private' }))

      RedmineChatTelegram::BotService.new(command, bot).call

      bot.verify
    end
  end

  describe 'new' do

    it "exucutes new_isssue command" do
      command = Telegrammer::DataTypes::Message
                .new(command_params.merge(
                      text: "/new",
                      chat: { id: 123, type: 'private' }))

      RedmineChatTelegram::Commands::NewIssueCommand.any_instance.expects(:execute)

      RedmineChatTelegram::BotService.new(command, bot).call
    end
  end

  describe 'cancel' do

    it "cancel executing command if it's exist" do
      command = Telegrammer::DataTypes::Message
                .new(command_params.merge(
                      text: "/cancel",
                      chat: { id: 123, type: 'private' }))
      account = ::TelegramCommon::Account.create(telegram_id: command.from.id, user_id: user.id)
      executing_command = RedmineChatTelegram::ExecutingCommand.create(name: 'new', account: account)
      RedmineChatTelegram::ExecutingCommand.any_instance.expects(:cancel)

      RedmineChatTelegram::BotService.new(command, bot).call
    end
  end

  it "runs executing command if it's present" do
    command = Telegrammer::DataTypes::Message
              .new(command_params.merge(
                    text: "hello",
                    chat: { id: 123, type: 'private' }))
    account = ::TelegramCommon::Account.create(telegram_id: command.from.id, user_id: user.id)
    executing_command = RedmineChatTelegram::ExecutingCommand.create(name: 'new', account: account)
    RedmineChatTelegram::ExecutingCommand.any_instance.expects(:continue)

    RedmineChatTelegram::BotService.new(command, bot).call
  end
end
