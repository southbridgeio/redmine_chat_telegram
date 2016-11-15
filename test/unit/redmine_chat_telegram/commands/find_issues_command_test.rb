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
    Setting['host_name'] = 'redmine.com'
    TelegramCommon::Account.create(telegram_id: command.from.id, user_id: user.id)
  end

  describe '/hot' do
    let(:command) { Telegrammer::DataTypes::Message.new(command_params.merge(text: '/hot')) }

    it 'sends list of issues assigned to user and updated today' do
      Issue.find(1).update(assigned_to: user)
      text = <<~HTML
        <b>Assigned to you issues with recent activity:</b>
        <a href="http://redmine.com/issues/1">#1</a>: Cannot print recipes
      HTML
      bot.expect(:send_message, nil, [{ chat_id: 123, text: text, parse_mode: 'HTML' }])
      RedmineChatTelegram::Commands::FindIssuesCommand.new(command, bot).execute
      bot.verify
    end
  end

  describe '/me' do
    let(:command) { Telegrammer::DataTypes::Message.new(command_params.merge(text: '/me')) }

    it 'sends assigned to user issues' do
      Issue.update_all(assigned_to_id: 2)
      Issue.second.update(assigned_to: user)
      text = <<~HTML
        <b>Assigned to you issues:</b>
        <a href="http://redmine.com/issues/2">#2</a>: Add ingredients categories
      HTML
      bot.expect(:send_message, nil, [{ chat_id: 123, text: text, parse_mode: 'HTML' }])
      RedmineChatTelegram::Commands::FindIssuesCommand.new(command, bot).execute
      bot.verify
    end
  end

  describe '/deadline' do
    let(:command) { Telegrammer::DataTypes::Message.new(command_params.merge(text: '/deadline')) }

    it 'sends assigned to user issues with deadline' do
      Issue.update_all(assigned_to_id: 2)
      Issue.third.update(assigned_to: user, due_date: Date.yesterday)
      text = <<~HTML
        <b>Assigned to you issues with expired deadline:</b>
        <a href="http://redmine.com/issues/3">#3</a>: Error 281 when updating a recipe
      HTML
      bot.expect(:send_message, nil, [{ chat_id: 123, text: text, parse_mode: 'HTML' }])
      RedmineChatTelegram::Commands::FindIssuesCommand.new(command, bot).execute
      bot.verify
    end
  end
end
