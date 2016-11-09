require File.expand_path('../../../../test_helper', __FILE__)
require 'minitest/mock'
require 'minitest/autorun'

class RedmineChatTelegram::Commands::LastIssuesNotesCommandTest < ActiveSupport::TestCase
  fixtures :projects, :trackers, :issues, :users, :issue_statuses, :journals

  let(:command) do
    Telegrammer::DataTypes::Message.new(
      chat: { id: 123, type: 'private' },
      message_id: 123_456,
      date: Date.today,
      from: { id: 998_899, first_name: 'Qw', last_name: 'Ert', username: 'qwert' },
      text: '/last')
  end

  let(:bot) { Minitest::Mock.new }
  let(:logger) { Logger.new(STDOUT) }
  let(:user) { User.find(1) }

  before do
    TelegramCommon::Account.create(telegram_id: command.from.id, user_id: user.id)
  end

  it 'sends last five updated issues with journals' do
    bot.expect(:send_message, nil, [{ chat_id: 123, text: "[#9](http://localhost:3000/issues/9) Blocked Issue ```text New issue```\n\n[#6](http://localhost:3000/issues/6) Issue of a private subproject ```text A comment with a private version.```_November 07, 2016 21:00_\n\n[#10](http://localhost:3000/issues/10) Issue Doing the Blocking ```text New issue```\n\n[#1](http://localhost:3000/issues/1) Cannot print recipes ```text Some notes with Redmine links: #2, r2.```_November 07, 2016 21:00_\n\n[#5](http://localhost:3000/issues/5) Subproject issue ```text New issue```\n\n", parse_mode: 'Markdown' }])

    RedmineChatTelegram::Commands::LastIssuesNotesCommand.new(command, bot).execute

    bot.verify
  end
end
