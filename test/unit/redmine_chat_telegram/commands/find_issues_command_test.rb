require File.expand_path('../../../../test_helper', __FILE__)

class RedmineChatTelegram::Commands::FindIssuesCommandTest < ActiveSupport::TestCase
  fixtures :projects, :trackers, :issues, :users, :issue_statuses, :roles

  let(:command_params) do
    {
      chat: { id: 123, type: 'private' },
      message_id: 123_456,
      date: Date.today.to_time.to_i,
      from: { id: 998_899, first_name: 'Qw', last_name: 'Ert', username: 'qwert' }
    }
  end

  let(:bot_token) { 'token' }
  let(:logger) { Logger.new(STDOUT) }
  let(:user) { User.find(1) }

  let(:url_base) { "#{Setting.protocol}://#{Setting.host_name}" }

  before do
    TelegramCommon::Account.create(telegram_id: command.from.id, user_id: user.id)
    Member.create!(project_id: 1, principal: user, role_ids: [1])
  end

  describe '/hot' do
    let(:command) { Telegram::Bot::Types::Message.new(command_params.merge(text: '/hot')) }

    it 'sends list of issues assigned to user and updated today' do
      Issue.find(1).update(assigned_to: user)
      text = <<~HTML
        <b>Assigned to you issues with recent activity:</b>
        <a href="#{url_base}/issues/1">#1</a>: Cannot print recipes
      HTML
      RedmineChatTelegram::Commands::BaseBotCommand.any_instance
        .expects(:send_message)
        .with(text)
      RedmineChatTelegram::Commands::FindIssuesCommand.new(command).execute
    end
  end

  describe '/me' do
    let(:command) { Telegram::Bot::Types::Message.new(command_params.merge(text: '/me')) }

    it 'sends assigned to user issues' do
      Issue.update_all(assigned_to_id: 2)
      Issue.second.update(assigned_to: user)
      text = <<~HTML
        <b>Assigned to you issues:</b>
        <a href="#{url_base}/issues/2">#2</a>: Add ingredients categories
      HTML
      RedmineChatTelegram::Commands::BaseBotCommand.any_instance
        .expects(:send_message)
        .with(text)
      RedmineChatTelegram::Commands::FindIssuesCommand.new(command).execute
    end
  end

  describe '/deadline' do
    let(:command) { Telegram::Bot::Types::Message.new(command_params.merge(text: '/deadline')) }

    it 'sends assigned to user issues with deadline' do
      Issue.update_all(assigned_to_id: 2)
      Issue.third.update(assigned_to: user, due_date: Date.yesterday)
      text = <<~HTML
        <b>Assigned to you issues with expired deadline:</b>
        <a href="#{url_base}/issues/3">#3</a>: Error 281 when updating a recipe
      HTML
      RedmineChatTelegram::Commands::BaseBotCommand.any_instance
        .expects(:send_message)
        .with(text)
      RedmineChatTelegram::Commands::FindIssuesCommand.new(command).execute
    end
  end
end
