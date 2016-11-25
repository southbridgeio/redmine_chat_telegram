module RedmineChatTelegram
  class GroupChatCreator
    attr_reader :issue, :user

    def initialize(issue, user)
      @issue = issue
      @user = user
    end

    def run
      subject  = if RedmineChatTelegram.mode.zero?
                   "#{issue.project.name} ##{issue.id}"
                 else
                   "#{issue.project.name} #{issue.id}"
                 end

      bot_name = Setting.plugin_redmine_chat_telegram['bot_name']

      cmd  = "create_group_chat \"#{subject}\" #{bot_name}"
      json = RedmineChatTelegram.run_cli_command(cmd, TELEGRAM_CLI_LOG)

      subject_for_cli = if RedmineChatTelegram.mode.zero?
                          subject.tr(' ', '_').tr('#', '@')
                        else
                          subject.tr(' ', '_').tr('#', '_')
                        end

      cmd  = "chat_info #{subject_for_cli}"
      json = RedmineChatTelegram.run_cli_command(cmd, TELEGRAM_CLI_LOG)

      telegram_id = if RedmineChatTelegram.mode.zero?
                      json['id']
                    else
                      json['peer_id']
                    end

      cmd  = "export_chat_link #{subject_for_cli}"
      json = RedmineChatTelegram.run_cli_command(cmd, TELEGRAM_CLI_LOG)

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
