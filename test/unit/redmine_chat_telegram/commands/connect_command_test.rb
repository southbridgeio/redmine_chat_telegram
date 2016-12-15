require File.expand_path('../../../../test_helper', __FILE__)
require 'minitest/mock'
require 'minitest/autorun'

class RedmineChatTelegram::Commands::ConnectCommandTest < ActiveSupport::TestCase
  fixtures :projects, :trackers, :issues, :users, :email_addresses

  let(:logger) { Logger.new(STDOUT) }
  let(:user) { User.find(1) }

  let(:command_params) do
    {
      chat: { id: 123, type: 'private' },
      message_id: 123_456,
      date: Date.today,
      from: { id: 998_899, first_name: 'Qw', last_name: 'Ert', username: 'qwert' }
    }
  end

  before do
    I18n.locale = 'en'
  end

  it 'sends what user not found if user not found' do
    RedmineChatTelegram::Commands::BaseBotCommand.any_instance
      .expects(:send_message)
      .with('User not found')

    command = Telegrammer::DataTypes::Message
              .new(command_params.merge(text: '/connect not-exist@mail.com'))
    RedmineChatTelegram::Commands::ConnectCommand.new(command, logger).execute
  end

  it 'sends what user already connected if user already connected' do
    RedmineChatTelegram::Commands::BaseBotCommand.any_instance
      .expects(:send_message)
      .with('Your accounts already connected')

    command = Telegrammer::DataTypes::Message
              .new(command_params.merge(
                     text: "/connect #{user.email_address.address}",
                     chat: { id: 123, type: 'private' }))

    ::TelegramCommon::Account.create(
      telegram_id: command.from.id,
      user_id: user.id)

    RedmineChatTelegram::Commands::ConnectCommand.new(command, logger).execute
  end

  it 'sends message with success if user found and not connected' do
    RedmineChatTelegram::Commands::BaseBotCommand.any_instance
      .expects(:send_message)
      .with("We sent email to address \"#{user.email_address.address}\". Please follow instructions from it.")

    TelegramCommon::Mailer.expects(:telegram_connect)
      .returns(Minitest::Mock.new.expect(:deliver, nil))

    command = Telegrammer::DataTypes::Message
              .new(command_params.merge(text: "/connect #{user.email_address.address}"))

    RedmineChatTelegram::Commands::ConnectCommand.new(command, logger).execute
  end
end
