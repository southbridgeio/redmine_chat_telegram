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
    I18n.locale = 'en'
    Setting['host_name'] = 'redmine.com'
    TelegramCommon::Account.create(telegram_id: command.from.id, user_id: user.id)
  end

  it 'sends last five updated issues with journals' do
    Issue.update_all(project_id: 1)
    Issue.where.not(id: [1, 5]).destroy_all
    issue_journal_time = I18n.l Issue.find(1).journals.last.created_on, format: :long

    text = "<a href=\"http://redmine.com/issues/1\">#1</a>: Cannot print recipes <pre> Some notes with Redmine links: #2, r2.</pre> <i>November 14, 2016 21:00</i>\n\n<a href=\"http://redmine.com/issues/5\">#5</a>: Subproject issue <pre>New issue</pre>\n\n"

    bot.expect(:send_message, nil, [{chat_id: 123, text: text, parse_mode: 'HTML'}])

    RedmineChatTelegram::Commands::LastIssuesNotesCommand.new(command, bot).execute

    bot.verify
  end
end
