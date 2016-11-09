require File.expand_path('../../../../test_helper', __FILE__)
require 'minitest/mock'
require 'minitest/autorun'

class RedmineChatTelegram::Commands::FindIssuesCommandTest < ActiveSupport::TestCase
  fixtures :projects, :trackers, :issues, :users, :issue_statuses

  let(:command_params) do
    {
      chat: { id: 123, type: 'private' },
      message_id: 123_456,
      date: Date.today,
      from: { id: 998_899, first_name: 'Qw', last_name: 'Ert', username: 'qwert' }
    }
  end

  let(:bot) { Minitest::Mock.new }
  let(:logger) { Logger.new(STDOUT) }
  let(:user) { User.find(1) }

  before do
    I18n.locale = 'en'
    TelegramCommon::Account.create(telegram_id: command.from.id, user_id: user.id)
  end

  describe '/hot' do
    let(:command) { Telegrammer::DataTypes::Message.new(command_params.merge(text: '/hot')) }

    it 'sends list of issues assigned to user and updated today' do
      Issue.find(1).update(assigned_to: user)
      bot.expect(:send_message, nil, [{ chat_id: 123, text: "*Assigned to you issues with recent activity:*\n[#1](http://localhost:3000/issues/1): Cannot print recipes\n", parse_mode: 'Markdown' }])
      RedmineChatTelegram::Commands::FindIssuesCommand.new(command, bot).execute
      bot.verify
    end
  end

  describe '/me' do
    let(:command) { Telegrammer::DataTypes::Message.new(command_params.merge(text: '/me')) }

    it 'sends assigned to user issues' do
      Issue.update_all(assigned_to_id: 2)
      Issue.second.update(assigned_to: user)
      bot.expect(:send_message, nil, [{ chat_id: 123, text: "*Assigned to you issues:*\n[#2](http://localhost:3000/issues/2): Add ingredients categories\n", parse_mode: 'Markdown' }])
      RedmineChatTelegram::Commands::FindIssuesCommand.new(command, bot).execute
      bot.verify
    end
  end

  describe '/deadline' do
    let(:command) { Telegrammer::DataTypes::Message.new(command_params.merge(text: '/deadline')) }

    it 'sends assigned to user issues with deadline' do
      Issue.update_all(assigned_to_id: 2)
      Issue.third.update(assigned_to: user, due_date: Date.yesterday)
      bot.expect(:send_message, nil, [{ chat_id: 123, text: "*Assigned to you issues with expired deadline:*\n[#3](http://localhost:3000/issues/3): Error 281 when updating a recipe\n", parse_mode: 'Markdown' }])
      RedmineChatTelegram::Commands::FindIssuesCommand.new(command, bot).execute
      bot.verify
    end
  end
end
