require File.expand_path('../../../../test_helper', __FILE__)

class RedmineChatTelegram::Commands::EditIssueCommandTest < ActiveSupport::TestCase
  fixtures :projects, :trackers, :issues, :users, :issue_statuses, :roles, :enabled_modules, :issue_relations

  let(:command_params) do
    {
      chat: { id: 123, type: 'private' },
      message_id: 123_456,
      date: Date.today,
      from: { id: 998_899, first_name: 'Qw', last_name: 'Ert', username: 'qwert' }
    }
  end

  let(:user) { User.find(2) }
  let(:project) { Project.find(2) }
  let(:account) { TelegramCommon::Account.create(telegram_id: 998_899, user_id: user.id) }
  let(:url_base) { "#{Setting.protocol}://#{Setting.host_name}" }

  before do
    account
    Member.create!(project_id: 2, principal: user, role_ids: [1])
  end

  describe 'step 1' do
    before do
      RedmineChatTelegram::ExecutingCommand.create(account: account, name: 'issue', data: {})
        .update(step_number: 1)
    end

    it 'offers to send hepl if not arguments' do
      command = Telegrammer::DataTypes::Message.new(command_params.merge(text: '/issue'))
      text = I18n.t("redmine_chat_telegram.bot.edit_issue.help")
      RedmineChatTelegram::Commands::BaseBotCommand.any_instance
        .expects(:send_message)
        .with(text)
      RedmineChatTelegram::Commands::EditIssueCommand.new(command).execute
    end

    it 'offers to select editing param if issue id is present' do
      command = Telegrammer::DataTypes::Message.new(command_params.merge(text: '/issue 1'))
      text = 'Select parameter to change. To cancel command use /cancel.'
      Telegrammer::DataTypes::ReplyKeyboardMarkup.expects(:new).returns(nil)
      RedmineChatTelegram::Commands::BaseBotCommand.any_instance
        .expects(:send_message)
        .with(text, reply_markup: nil)
      RedmineChatTelegram::Commands::EditIssueCommand.new(command).execute
    end

    it 'offers to select project' do
      command = Telegrammer::DataTypes::Message.new(command_params.merge(text: '/issue project'))
      text = 'Select project.'
      Telegrammer::DataTypes::ReplyKeyboardMarkup.expects(:new).returns(nil)
      RedmineChatTelegram::Commands::BaseBotCommand.any_instance
        .expects(:send_message)
        .with(text, reply_markup: nil)
      RedmineChatTelegram::Commands::EditIssueCommand.new(command).execute
    end

    it 'offers to select issue' do
      command = Telegrammer::DataTypes::Message.new(command_params.merge(text: '/issue OnlineStore'))
      text = <<~HTML
        <b>List issues of project:</b>
        <a href="#{url_base}/issues/4">#4</a>: Issue on project 2
      HTML
      Telegrammer::DataTypes::ReplyKeyboardMarkup.expects(:new).returns(nil)
      RedmineChatTelegram::Commands::BaseBotCommand.any_instance
        .expects(:send_message)
        .with(text, reply_markup: nil)
      RedmineChatTelegram::Commands::EditIssueCommand.new(command).execute
    end

    it 'offers to send list of issues assigned to user and updated today' do
      command = Telegrammer::DataTypes::Message.new(command_params.merge(text: '/issue hot'))
      Issue.find(4).update(assigned_to: user)
      text = <<~HTML
        <b>Assigned to you issues with recent activity:</b>
        <a href="#{url_base}/issues/4">#4</a>: Issue on project 2
      HTML
      Telegrammer::DataTypes::ReplyKeyboardMarkup.expects(:new).returns(nil)
      RedmineChatTelegram::Commands::BaseBotCommand.any_instance
        .expects(:send_message)
        .with(text, reply_markup: nil)
      RedmineChatTelegram::Commands::EditIssueCommand.new(command).execute
    end
  end

  describe 'step 2' do
    before do
      RedmineChatTelegram::ExecutingCommand.create(account: account, name: 'issue', data: {})
        .update(step_number: 2)
    end

    it 'offer to selecte issue if project is found' do
      command = Telegrammer::DataTypes::Message.new(command_params.merge(text: 'OnlineStore'))
      text = <<~HTML
        <b>List issues of project:</b>
        <a href="#{url_base}/issues/4">#4</a>: Issue on project 2
      HTML
      Telegrammer::DataTypes::ReplyKeyboardMarkup.expects(:new).returns(nil)
      RedmineChatTelegram::Commands::BaseBotCommand.any_instance
        .expects(:send_message)
        .with(text, reply_markup: nil)
      RedmineChatTelegram::Commands::EditIssueCommand.new(command).execute
    end

    it 'finish command if project not found' do
      command = Telegrammer::DataTypes::Message.new(command_params.merge(text: '/issue incorrect_project_name'))
      text = 'Value is incorrect. Command was finished.'
      Telegrammer::DataTypes::ReplyKeyboardHide.expects(:new).returns(nil)
      RedmineChatTelegram::Commands::BaseBotCommand.any_instance
        .expects(:send_message)
        .with(text, reply_markup: nil)
      RedmineChatTelegram::Commands::EditIssueCommand.new(command).execute
    end
  end

  describe 'step 3' do
  before do
    RedmineChatTelegram::ExecutingCommand.create(account: account, name: 'issue', data: {})
      .update(step_number: 3)
  end

  it 'offer to selecte editing params if issue is found' do
    command = Telegrammer::DataTypes::Message.new(command_params.merge(text: '1'))
    text = 'Select parameter to change. To cancel command use /cancel.'
    Telegrammer::DataTypes::ReplyKeyboardMarkup.expects(:new).returns(nil)
    RedmineChatTelegram::Commands::BaseBotCommand.any_instance
      .expects(:send_message)
      .with(text, reply_markup: nil)
    RedmineChatTelegram::Commands::EditIssueCommand.new(command).execute
  end

  it 'finish command if issue not found' do
    command = Telegrammer::DataTypes::Message.new(command_params.merge(text: '/issue 999'))
    text = 'Value is incorrect. Command was finished.'
    Telegrammer::DataTypes::ReplyKeyboardHide.expects(:new).returns(nil)
    RedmineChatTelegram::Commands::BaseBotCommand.any_instance
      .expects(:send_message)
      .with(text, reply_markup: nil)
    RedmineChatTelegram::Commands::EditIssueCommand.new(command).execute
  end
end

  describe 'step 4' do
    before do
      RedmineChatTelegram::ExecutingCommand
        .create(account: account, name: 'issue', data: {issue_id: 1})
        .update(step_number: 4)
    end

    it 'offerts to send new value for editing param' do
      command = Telegrammer::DataTypes::Message.new(command_params.merge(text: 'status'))
      text = 'Select status.'
      Telegrammer::DataTypes::ReplyKeyboardMarkup.expects(:new).returns(nil)
      RedmineChatTelegram::Commands::BaseBotCommand.any_instance
        .expects(:send_message)
        .with(text, reply_markup: nil)
      RedmineChatTelegram::Commands::EditIssueCommand.new(command).execute
    end

    it 'finish command if params is incorrect' do
      command = Telegrammer::DataTypes::Message.new(command_params.merge(text: 'incorrect'))
      text = 'Value is incorrect. Command was finished.'
      Telegrammer::DataTypes::ReplyKeyboardHide.expects(:new).returns(nil)
      RedmineChatTelegram::Commands::BaseBotCommand.any_instance
        .expects(:send_message)
        .with(text, reply_markup: nil)
      RedmineChatTelegram::Commands::EditIssueCommand.new(command).execute
    end
  end

  describe 'step 5' do
    before do
      RedmineChatTelegram::ExecutingCommand
        .create(account: account, name: 'issue', data: {issue_id: 1, attribute_name: 'subject' })
        .update(step_number: 5)
    end

    it 'updates issue if value is correct' do
      command =  Telegrammer::DataTypes::Message.new(command_params.merge(text: 'new subject'))
      text = '<strong>Subject</strong> changed from <i>Cannot print recipes</i> to <i>new subject</i>'
      RedmineChatTelegram::Commands::BaseBotCommand.any_instance
        .expects(:send_message)
        .with(text)
      RedmineChatTelegram::Commands::EditIssueCommand.new(command).execute
    end

    it 'finish command with error if value is incorrect' do
      command =  Telegrammer::DataTypes::Message.new(command_params.merge(text: ''))
      text = 'Failed to edit the issue. Perhaps you entered the wrong data or you do not have the access.'
      RedmineChatTelegram::Commands::BaseBotCommand.any_instance
        .expects(:send_message)
        .with(text)
      RedmineChatTelegram::Commands::EditIssueCommand.new(command).execute
    end
  end
end
