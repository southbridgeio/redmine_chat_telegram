module RedmineChatTelegram
  class GroupChatCreator
    attr_reader :issue, :user

    def initialize(issue, user)
      @issue = issue
      @user = user
    end

    def run
      subject  = "#{issue.project.name} #{issue.id}"

      bot_name = Setting.plugin_redmine_chat_telegram['bot_name']

      cmd  = "create_group_chat \"#{subject}\" #{bot_name}"
      json = RedmineChatTelegram.socket_cli_command(cmd, TELEGRAM_CLI_LOG)

      subject_for_cli = if RedmineChatTelegram.mode.zero?
                          subject.tr(' ', '_').tr('#', '@')
                        else
                          subject.tr(' ', '_').tr('#', '_')
                        end

      sleep 1
      # TODO: 1. replace it by waiting message from bot and getting chat_id from DB
      # TODO: 2. remove RedmineChatTelegram.mode (telegram_cli_mode)

      cmd  = "chat_info #{subject_for_cli}"
      json = RedmineChatTelegram.socket_cli_command(cmd, TELEGRAM_CLI_LOG)

      telegram_id = json['peer_id'] || json['id']

      # get chat_id from DB
      #
      # cmd  = "export_chat_link chat##{chat_id.abs}"

      cmd  = "export_chat_link #{subject_for_cli}"
      json = RedmineChatTelegram.socket_cli_command(cmd, TELEGRAM_CLI_LOG)

      telegram_chat_url = json['result']

      if issue.telegram_group.present?
        issue.telegram_group.update telegram_id: telegram_id,
                                    shared_url:  telegram_chat_url
      else
        issue.create_telegram_group telegram_id: telegram_id,
                                    shared_url:  telegram_chat_url
      end

      journal_text = I18n.t('redmine_chat_telegram.journal.chat_was_created',
                            telegram_chat_url: telegram_chat_url)

      begin
        issue.init_journal(user, journal_text)
        issue.save
      rescue ActiveRecord::StaleObjectError
        issue.reload
        retry
      end
    end
  end
end
