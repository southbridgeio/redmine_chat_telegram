require File.expand_path('../../../../test_helper', __FILE__)

class RedmineChatTelegram::Commands::EditIssueCommandTest < ActiveSupport::TestCase
  fixtures :projects, :trackers, :issues, :users, :issue_statuses, :roles, :enabled_modules, :issue_relations

  let(:command_params) do
    {
      chat: { id: 123, type: 'private' },
      message_id: 123_456,
      date: Date.today.to_time.to_i,
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
      RedmineChatTelegram::ExecutingCommand.create(account: account, name: 'issue', data: {current_page: 1})
        .update(step_number: 1)
    end

    it 'offers to send hepl if not arguments' do
      command = Telegram::Bot::Types::Message.new(command_params.merge(text: '/issue'))
      text = I18n.t('redmine_chat_telegram.bot.edit_issue.help')
      RedmineChatTelegram::Commands::BaseBotCommand.any_instance
        .expects(:send_message)
        .with(text)
      RedmineChatTelegram::Commands::EditIssueCommand.new(command).execute
    end

    it 'offers to select editing param if issue id is present' do
      command = Telegram::Bot::Types::Message.new(command_params.merge(text: '/issue 1'))
      text = [
        I18n.t('redmine_chat_telegram.bot.edit_issue.select_param'),
        I18n.t('redmine_chat_telegram.bot.edit_issue.cancel_hint')
      ].join(' ')
      Telegram::Bot::Types::ReplyKeyboardMarkup.expects(:new).returns(nil)
      RedmineChatTelegram::Commands::BaseBotCommand.any_instance
        .expects(:send_message)
        .with(text, reply_markup: nil)
      RedmineChatTelegram::Commands::EditIssueCommand.new(command).execute
    end

    it 'offers to select project' do
      command = Telegram::Bot::Types::Message.new(command_params.merge(text: '/issue project'))
      text = I18n.t('redmine_chat_telegram.bot.new_issue.choice_project_without_page')
      Telegram::Bot::Types::ReplyKeyboardMarkup.expects(:new).returns(nil)
      RedmineChatTelegram::Commands::BaseBotCommand.any_instance
        .expects(:send_message)
        .with(text, reply_markup: nil)
      RedmineChatTelegram::Commands::EditIssueCommand.new(command).execute
    end

    it 'offers to select issue' do
      project = Project.find(2)
      command = Telegram::Bot::Types::Message.new(command_params.merge(text: "/issue #{project.name}"))

      issue = project.issues.first

      text = <<~HTML
        <b>List issues of project:</b>
        <a href="#{url_base}/issues/#{issue.id}">##{issue.id}</a>: #{issue.subject}
      HTML

      RedmineChatTelegram::Commands::BaseBotCommand.any_instance
        .expects(:send_message)
        .with(text)

      text_2 = [
        I18n.t('redmine_chat_telegram.bot.edit_issue.input_id'),
        I18n.t('redmine_chat_telegram.bot.edit_issue.cancel_hint')
      ].join(' ')

      RedmineChatTelegram::Commands::BaseBotCommand.any_instance
        .expects(:send_message)
        .with(text_2)

      RedmineChatTelegram::Commands::EditIssueCommand.new(command).execute
    end

    it 'offers to send list of issues assigned to user and updated today' do
      command = Telegram::Bot::Types::Message.new(command_params.merge(text: '/issue hot'))

      issue = Issue.find(5)
      issue.update(assigned_to: user)

      text = <<~HTML
        <b>Assigned to you issues with recent activity:</b>
        <a href="#{url_base}/issues/#{issue.id}">##{issue.id}</a>: #{issue.subject}
      HTML

      RedmineChatTelegram::Commands::BaseBotCommand.any_instance
        .expects(:send_message)
        .with(text)

      text_2 = [
        I18n.t('redmine_chat_telegram.bot.edit_issue.input_id'),
        I18n.t('redmine_chat_telegram.bot.edit_issue.cancel_hint')
      ].join(' ')

      RedmineChatTelegram::Commands::BaseBotCommand.any_instance
        .expects(:send_message)
        .with(text_2)

      RedmineChatTelegram::Commands::EditIssueCommand.new(command).execute
    end
  end

  describe 'step 2' do
    before do
      RedmineChatTelegram::ExecutingCommand.create(account: account, name: 'issue', data: {})
        .update(step_number: 2)
    end

    it 'offer to selecte issue if project is found' do
      project = Project.find(2)
      issue = Issue.find(4)
      command = Telegram::Bot::Types::Message.new(command_params.merge(text: project.name))
      text = <<~HTML
        <b>List issues of project:</b>
        <a href="#{url_base}/issues/#{issue.id}">##{issue.id}</a>: #{issue.subject}
      HTML

      RedmineChatTelegram::Commands::BaseBotCommand.any_instance
        .expects(:send_message)
        .with(text)

      text_2 = [
        I18n.t('redmine_chat_telegram.bot.edit_issue.input_id'),
        I18n.t('redmine_chat_telegram.bot.edit_issue.cancel_hint')
      ].join(' ')

      RedmineChatTelegram::Commands::BaseBotCommand.any_instance
        .expects(:send_message)
        .with(text_2)

      RedmineChatTelegram::Commands::EditIssueCommand.new(command).execute
    end

    it 'finish command if project not found' do
      command = Telegram::Bot::Types::Message.new(command_params.merge(text: '/issue incorrect_project_name'))
      text = I18n.t('redmine_chat_telegram.bot.edit_issue.incorrect_value')
      Telegram::Bot::Types::ReplyKeyboardRemove.expects(:new).returns(nil)
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
      command = Telegram::Bot::Types::Message.new(command_params.merge(text: '1'))
      text = [
        I18n.t('redmine_chat_telegram.bot.edit_issue.select_param'),
        I18n.t('redmine_chat_telegram.bot.edit_issue.cancel_hint')
      ].join(' ')
      Telegram::Bot::Types::ReplyKeyboardMarkup.expects(:new).returns(nil)
      RedmineChatTelegram::Commands::BaseBotCommand.any_instance
        .expects(:send_message)
        .with(text, reply_markup: nil)
      RedmineChatTelegram::Commands::EditIssueCommand.new(command).execute
    end

    it 'finish command if issue not found' do
      command = Telegram::Bot::Types::Message.new(command_params.merge(text: '/issue 999'))
      text = I18n.t('redmine_chat_telegram.bot.edit_issue.incorrect_value')
      Telegram::Bot::Types::ReplyKeyboardRemove.expects(:new).returns(nil)
      RedmineChatTelegram::Commands::BaseBotCommand.any_instance
        .expects(:send_message)
        .with(text, reply_markup: nil)
      RedmineChatTelegram::Commands::EditIssueCommand.new(command).execute
    end
  end

  describe 'step 4' do
    before do
      RedmineChatTelegram::ExecutingCommand
        .create(account: account, name: 'issue', data: { issue_id: 1 })
        .update(step_number: 4)
    end

    it 'offerts to send new value for editing param' do
      command = Telegram::Bot::Types::Message.new(command_params.merge(text: 'status'))
      text = I18n.t('redmine_chat_telegram.bot.edit_issue.select_status')
      Telegram::Bot::Types::ReplyKeyboardMarkup.expects(:new).returns(nil)
      RedmineChatTelegram::Commands::BaseBotCommand.any_instance
        .expects(:send_message)
        .with(text, reply_markup: nil)
      RedmineChatTelegram::Commands::EditIssueCommand.new(command).execute
    end

    it 'finish command if params is incorrect' do
      command = Telegram::Bot::Types::Message.new(command_params.merge(text: 'incorrect'))
      text = I18n.t('redmine_chat_telegram.bot.edit_issue.incorrect_value')
      Telegram::Bot::Types::ReplyKeyboardRemove.expects(:new).returns(nil)
      RedmineChatTelegram::Commands::BaseBotCommand.any_instance
        .expects(:send_message)
        .with(text, reply_markup: nil)
      RedmineChatTelegram::Commands::EditIssueCommand.new(command).execute
    end
  end

  describe 'step 5' do
    before do
      RedmineChatTelegram::ExecutingCommand
        .create(account: account, name: 'issue', data: { issue_id: 1, attribute_name: 'subject' })
        .update(step_number: 5)
    end

    it 'updates issue if value is correct' do
      command =  Telegram::Bot::Types::Message.new(command_params.merge(text: 'new subject'))
      text = '<strong>Subject</strong> changed from <i>Cannot print recipes</i> to <i>new subject</i>'
      RedmineChatTelegram::Commands::BaseBotCommand.any_instance
        .expects(:send_message)
        .with(text)
      RedmineChatTelegram::Commands::EditIssueCommand.new(command).execute
    end

    it 'finish command with error if value is incorrect' do
      command =  Telegram::Bot::Types::Message.new(command_params.merge(text: ''))
      text = I18n.t('redmine_chat_telegram.bot.error_editing_issue')
      RedmineChatTelegram::Commands::BaseBotCommand.any_instance
        .expects(:send_message)
        .with(text)
      RedmineChatTelegram::Commands::EditIssueCommand.new(command).execute
    end
  end
end
