require File.expand_path('../../../../test_helper', __FILE__)

class RedmineChatTelegram::Commands::BotCommandTest < ActiveSupport::TestCase
  fixtures :projects, :trackers, :issues, :users, :email_addresses

  let(:user) { User.find(1) }

  let(:command_params) do
    {
      chat: { id: 123, type: 'private' },
      message_id: 123_456,
      date: Date.today.to_time.to_i,
      from: { id: 998_899, first_name: 'Qw', last_name: 'Ert', username: 'qwert' }
    }
  end

  describe 'cancel' do
    it "cancel executing command if it's exist" do
      command = Telegram::Bot::Types::Message
                .new(command_params.merge(text: '/cancel'))
      account = ::TelegramCommon::Account.create(telegram_id: command.from.id, user_id: user.id)
      executing_command = RedmineChatTelegram::ExecutingCommand.create(name: 'new', account: account)
      RedmineChatTelegram::ExecutingCommand.any_instance.expects(:cancel)

      RedmineChatTelegram::Commands::BotCommand.new(command).execute
    end
  end

  it "runs executing command if it's present" do
    command = Telegram::Bot::Types::Message
              .new(command_params.merge(text: 'hello'))
    account = ::TelegramCommon::Account.create(telegram_id: command.from.id, user_id: user.id)
    executing_command = RedmineChatTelegram::ExecutingCommand.create(name: 'new', account: account)
    RedmineChatTelegram::ExecutingCommand.any_instance.expects(:continue)

    RedmineChatTelegram::Commands::BotCommand.new(command).execute
  end
end
