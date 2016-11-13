require File.expand_path('../../../../test_helper', __FILE__)
require 'minitest/mock'
require 'minitest/autorun'

class RedmineChatTelegram::Commands::NewIssueCommandTest < ActiveSupport::TestCase
  fixtures :projects, :trackers, :issues, :users, :email_addresses, :roles, :issue_statuses

  let(:bot) { Minitest::Mock.new }
  let(:issue) { Issue.find(1) }
  let(:user) { User.find(1) }

  let(:command_params) do
    {
      chat: { id: 123, type: 'private' },
      message_id: 123_456,
      date: Date.today,
      from: { id: 998_899, first_name: 'Qw', last_name: 'Ert', username: 'qwert' }
    }
  end

  let(:command) { Telegrammer::DataTypes::Message.new(command_params) }

  before do
    I18n.locale = 'ru'
  end

  describe '#execute' do
    it 'sends that account not found if there is no accout' do
      bot.expect(:send_message, nil, [{ chat_id: 123, text: 'Аккаунт не найден.' }])
      RedmineChatTelegram::Commands::NewIssueCommand.new(command, bot).execute
      bot.verify
    end

    describe 'when account is present' do
      before do
        @account = ::TelegramCommon::Account.create(telegram_id: 998_899, user_id: user.id)
      end

      describe 'step 1' do
        it 'sends projects available for the user' do
          project_list = [['eCookbook', 'Private child of eCookbook'],
                          ['Child of private child', 'eCookbook Subproject 1'],
                          ['eCookbook Subproject 2', 'OnlineStore']]

          Telegrammer::DataTypes::ReplyKeyboardMarkup.expects(:new)
            .with(keyboard: project_list, one_time_keyboard: true, resize_keyboard: true)
            .returns(nil)

          bot.expect(
            :send_message,
            nil,
            [{ chat_id: 123, text: 'Выберите проект.', reply_markup: nil }])

          RedmineChatTelegram::Commands::NewIssueCommand.new(command, bot).execute
          bot.verify
        end
      end

      describe 'step 2' do
        before do
          RedmineChatTelegram::ExecutingCommand.create(account: @account, name: 'new')
            .update(step_number: 2)
        end

        it 'sends list of project members if they are exist' do
          member = Member.create(project_id: 1, user_id: 1)
          member.roles << Role.first
          member.save

          command = Telegrammer::DataTypes::Message
                    .new(command_params.merge(text: Project.first.name))

          # TODO: почему-то изменился этот массив. Вообще логика не достаточно некомпозирована. Сходу не понять что
          # это за список пользоватлей. Можно будет обсудить по скайпу как тут лушче сделать.
          # users_list = [['Redmine Admin']]
          users_list = [['Без пользователя', 'Redmine Admin']]
          Telegrammer::DataTypes::ReplyKeyboardMarkup.expects(:new)
            .with(keyboard: users_list, one_time_keyboard: true, resize_keyboard: true)
            .returns(nil)

          bot.expect(
            :send_message,
            nil,
            [{ chat_id: 123, text: 'Выберите кому назначить задачу.', reply_markup: nil }])

          RedmineChatTelegram::Commands::NewIssueCommand.new(command, bot).execute
          bot.verify
        end

        it 'sends message that users are not found it there is no project members' do
          bot.expect(
            :send_message,
            nil,
            [{ chat_id: 123, text: 'Не найдено пользователей для выбранного проекта.' }])

          RedmineChatTelegram::Commands::NewIssueCommand.new(command, bot).execute
          bot.verify
        end
      end

      describe 'step 3' do
        before do
          RedmineChatTelegram::ExecutingCommand.create(account: @account, name: 'new', data: {})
            .update(step_number: 3)
        end

        it 'asks to send issue subject' do
          command = Telegrammer::DataTypes::Message
                    .new(command_params.merge(text: 'Redmine Admin'))

          bot.expect(
            :send_message,
            nil,
            [{ chat_id: 123, text: 'Введите тему задачи.' }])

          RedmineChatTelegram::Commands::NewIssueCommand.new(command, bot).execute
          bot.verify
        end
      end

      describe 'step 4' do
        before do
          RedmineChatTelegram::ExecutingCommand.create(account: @account, name: 'new', data: {})
            .update(step_number: 4)
        end

        it 'asks to send issue text' do
          command = Telegrammer::DataTypes::Message
                    .new(command_params.merge(text: 'issue subject'))

          bot.expect(
            :send_message,
            nil,
            [{ chat_id: 123, text: 'Введите текст задачи.' }])

          RedmineChatTelegram::Commands::NewIssueCommand.new(command, bot).execute
          bot.verify
        end
      end

      describe 'step 5' do
        before do
          IssuePriority.create(is_default: true, name: 'normal')
          Project.find(1).trackers << Tracker.first
          Setting.host_name = 'redmine.com'
          RedmineChatTelegram::ExecutingCommand.create(
            account: @account,
            name: 'new',
            data: { project_name: 'eCookbook',
                    user: { firstname: 'Redmine',
                            lastname: 'Admin' },
                    subject: 'Issue created from telegram' }).update(step_number: 5)
        end

        let(:command) { Telegrammer::DataTypes::Message.new(command_params.merge(text: 'issue text')) }

        it 'sends message with link to the created issue' do
          new_issue_id = Issue.last.id + 1
          Telegrammer::DataTypes::ReplyKeyboardHide.expects(:new)
            .with(hide_keyboard: true)
            .returns(nil)
          bot.expect(
            :send_message,
            nil,
            [{ chat_id: 123,
               text: "Задача создана: [#15](http://redmine.com/issues/#{new_issue_id})",
               parse_mode: 'Markdown',
               reply_markup: nil }])
          RedmineChatTelegram::Commands::NewIssueCommand.new(command, bot).execute
          bot.verify
        end
      end
    end
  end
end
