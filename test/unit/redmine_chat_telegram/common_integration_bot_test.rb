require File.expand_path('../../../test_helper', __FILE__)

class RedmineChatTelegram::CommonIntegrationBotTest < ActiveSupport::TestCase
  fixtures :users, :email_addresses, :roles

  context '/start' do
    setup do
      @telegram_message = Telegrammer::DataTypes::Message.new(
        from: { id:         123,
                username:   'dhh',
                first_name: 'David',
                last_name:  'Haselman' },
        chat: { id: 123,
                type: 'private' },
        text: '/start'
      )

      @bot_service = RedmineChatTelegram::Bot.new(@telegram_message)
    end

    context 'without user' do
      setup do
        RedmineChatTelegram::Bot.any_instance
            .expects(:send_message)
            .with(I18n.t('telegram_common.bot.start.instruction_html'))
      end

      should 'create telegram account' do
        assert_difference('TelegramCommon::Account.count') do
          @bot_service.call
        end

        telegram_account = TelegramCommon::Account.last
        assert_equal 123, telegram_account.telegram_id
        assert_equal 'dhh', telegram_account.username
        assert_equal 'David', telegram_account.first_name
        assert_equal 'Haselman', telegram_account.last_name
        assert telegram_account.active
      end

      should 'update telegram account' do
        telegram_account = TelegramCommon::Account.create(telegram_id: 123, username: 'test', first_name: 'f', last_name: 'l')

        assert_no_difference('TelegramCommon::Account.count') do
          @bot_service.call
        end

        telegram_account.reload

        assert_equal 'dhh', telegram_account.username
        assert_equal 'David', telegram_account.first_name
        assert_equal 'Haselman', telegram_account.last_name
      end

      should 'activate telegram account' do
        actual = TelegramCommon::Account.create(telegram_id: 123, active: false)

        assert_no_difference('TelegramCommon::Account.count') do
          @bot_service.call
        end

        actual.reload

        assert actual.active
      end
    end
  end

  context 'wrong command context' do
    context 'private' do
      setup do
        @telegram_message = Telegrammer::DataTypes::Message.new(
          from: { id:         123,
                  username:   'abc',
                  first_name: 'Antony',
                  last_name:  'Brown' },
          chat: { id: 123,
                  type: 'private' },
          text: '/task'
        )

        @bot_service = RedmineChatTelegram::Bot.new(@telegram_message)
      end

      should 'send message about group command' do
        RedmineChatTelegram::Bot.any_instance.expects(:send_message)
          .with(I18n.t('telegram_common.bot.private.group_command'))
        @bot_service.call
      end
    end

    context 'group' do
      setup do
        @telegram_message = Telegrammer::DataTypes::Message.new(
          from: { id:         123,
                  username:   'abc',
                  first_name: 'Antony',
                  last_name:  'Brown' },
          chat: { id: -123,
                  type: 'group' },
          text: '/deadline'
        )

        @bot_service = RedmineChatTelegram::Bot.new(@telegram_message)
      end

      should 'send message about private command' do
        RedmineChatTelegram::Bot.any_instance.expects(:send_message)
          .with(I18n.t('telegram_common.bot.group.private_command'))
        @bot_service.call
      end
    end
  end

  context '/help' do
    context 'private' do
      setup do
        @telegram_message = Telegrammer::DataTypes::Message.new(
          from: { id:         123,
                  username:   'abc',
                  first_name: 'Antony',
                  last_name:  'Brown' },
          chat: { id: 123,
                  type: 'private' },
          text: '/help'
        )

        @bot_service = RedmineChatTelegram::Bot.new(@telegram_message)
      end

      should 'send help for private chat' do
        RedmineChatTelegram::Bot.any_instance.stubs(:private_ext_commands).returns([])
        text = <<~TEXT
          /start - #{I18n.t('redmine_chat_telegram.bot.private.help.start')}
          /connect - #{I18n.t('redmine_chat_telegram.bot.private.help.connect')}
          /help - #{I18n.t('redmine_chat_telegram.bot.private.help.help')}
          /new - #{I18n.t('redmine_chat_telegram.bot.private.help.new')}
          /hot - #{I18n.t('redmine_chat_telegram.bot.private.help.hot')}
          /me - #{I18n.t('redmine_chat_telegram.bot.private.help.me')}
          /deadline - #{I18n.t('redmine_chat_telegram.bot.private.help.deadline')}
          /dl - #{I18n.t('redmine_chat_telegram.bot.private.help.dl')}
          /spent - #{I18n.t('redmine_chat_telegram.bot.private.help.spent')}
          /yspent - #{I18n.t('redmine_chat_telegram.bot.private.help.yspent')}
          /last - #{I18n.t('redmine_chat_telegram.bot.private.help.last')}
          /chat - #{I18n.t('redmine_chat_telegram.bot.private.help.chat')}
          /issue - #{I18n.t('redmine_chat_telegram.bot.private.help.issue')}
        TEXT

        RedmineChatTelegram::Bot.any_instance.expects(:send_message).with(text.chomp)
        @bot_service.call
      end
    end

    context 'group' do
      setup do
        @telegram_message = Telegrammer::DataTypes::Message.new(
          from: { id:         123,
                  username:   'abc',
                  first_name: 'Antony',
                  last_name:  'Brown' },
          chat: { id: -123,
                  type: 'group' },
          text: '/help'
        )

        @bot_service = RedmineChatTelegram::Bot.new(@telegram_message)
      end

      should 'send help for private chat' do
        text = <<~TEXT
          /help - #{I18n.t('redmine_chat_telegram.bot.group.help.help')}
          /task - #{I18n.t('redmine_chat_telegram.bot.group.help.task')}
          /link - #{I18n.t('redmine_chat_telegram.bot.group.help.link')}
          /url - #{I18n.t('redmine_chat_telegram.bot.group.help.url')}
          /log - #{I18n.t('redmine_chat_telegram.bot.group.help.log')}
        TEXT

        RedmineChatTelegram::Bot.any_instance.expects(:send_message).with(text.chomp)
        @bot_service.call
      end
    end
  end
end
