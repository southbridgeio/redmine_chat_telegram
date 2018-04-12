require File.expand_path('../../../test_helper', __FILE__)

class RedmineChatTelegram::CommonIntegrationBotTest < ActiveSupport::TestCase
  fixtures :users, :email_addresses, :roles

  context 'wrong command context' do
    context 'private' do
      setup do
        @telegram_message = Telegram::Bot::Types::Message.new(
          from: { id:         123,
                  username:   'abc',
                  first_name: 'Antony',
                  last_name:  'Brown' },
          chat: { id: 123,
                  type: 'private' },
          text: '/url'
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
        @telegram_message = Telegram::Bot::Types::Message.new(
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
        @telegram_message = Telegram::Bot::Types::Message.new(
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
          Redmine Chat Telegram:
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
          /task - #{I18n.t('redmine_chat_telegram.bot.private.help.task')}
          /issue - #{I18n.t('redmine_chat_telegram.bot.private.help.issue')}
          /ih - #{I18n.t('redmine_chat_telegram.bot.private.help.ih')}
          /th - #{I18n.t('redmine_chat_telegram.bot.private.help.th')}
        TEXT

        RedmineChatTelegram::Bot.any_instance.expects(:send_message).with(text.chomp)
        @bot_service.call
      end
    end

    context 'group' do
      setup do
        @telegram_message = Telegram::Bot::Types::Message.new(
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
          Redmine Chat Telegram:
          /help - #{I18n.t('redmine_chat_telegram.bot.group.help.help')}
          /task - #{I18n.t('redmine_chat_telegram.bot.group.help.task')}
          /link - #{I18n.t('redmine_chat_telegram.bot.group.help.link')}
          /url - #{I18n.t('redmine_chat_telegram.bot.group.help.url')}
          /log - #{I18n.t('redmine_chat_telegram.bot.group.help.log')}
          /subject - #{I18n.t('redmine_chat_telegram.bot.group.help.subject')}
          /start_date - #{I18n.t('redmine_chat_telegram.bot.group.help.start_date')}
          /due_date - #{I18n.t('redmine_chat_telegram.bot.group.help.due_date')}
          /estimated_hours - #{I18n.t('redmine_chat_telegram.bot.group.help.estimated_hours')}
          /done_ratio - #{I18n.t('redmine_chat_telegram.bot.group.help.done_ratio')}
          /project - #{I18n.t('redmine_chat_telegram.bot.group.help.project')}
          /tracker - #{I18n.t('redmine_chat_telegram.bot.group.help.tracker')}
          /status - #{I18n.t('redmine_chat_telegram.bot.group.help.status')}
          /priority - #{I18n.t('redmine_chat_telegram.bot.group.help.priority')}
          /assigned_to - #{I18n.t('redmine_chat_telegram.bot.group.help.assigned_to')}
          /subject_chat - #{I18n.t('redmine_chat_telegram.bot.group.help.subject_chat')}
          #{I18n.t('redmine_chat_telegram.bot.group.help.hint')}
        TEXT

        RedmineChatTelegram::Bot.any_instance.expects(:send_message).with(text.chomp)
        @bot_service.call
      end
    end
  end
end
