class TelegramGroupChatsController < ApplicationController
  unloadable

  def create
    current_user = User.current

    cli_base = RedmineChatTelegram.cli_base

    @issue = Issue.visible.find(params[:issue_id])

    subject  = "#{@issue.project.name} ##{@issue.id}"
    bot_name = Setting.plugin_redmine_chat_telegram['bot_name']

    cmd    = %(#{cli_base} "create_group_chat \\"#{subject}\\" #{bot_name}" )
    result = RedmineChatTelegram.run_command_with_logging(cmd, TELEGRAM_CLI_LOG)

    telegram_id = result.match(/chat#(\d+)/)[1].to_i
    chat_id     = result.match(/chat#(\d+)/).to_s

    cmd    = "#{cli_base} \"export_chat_link #{chat_id}\""
    result = RedmineChatTelegram.run_command_with_logging(cmd, TELEGRAM_CLI_LOG)

    telegram_chat_url = result.match(/https:\/\/telegram.me\/joinchat\/[\w-]+/).to_s

    if @issue.telegram_group.present?
      @issue.telegram_group.update telegram_id: telegram_id,
                                   shared_url:  telegram_chat_url
    else
      @issue.create_telegram_group telegram_id: telegram_id,
                                   shared_url:  telegram_chat_url
    end

    journal_text = I18n.t('redmine_chat_telegram.journal.chat_was_created',
                          telegram_chat_url: telegram_chat_url)

    begin
      @issue.init_journal(current_user, journal_text)
      @issue.save
    rescue ActiveRecord::StaleObjectError
      @issue.reload
      retry
    end

    @project = @issue.project

    @last_journal = @issue.journals.visible.order("created_on").last
    new_journal_path = "#{issue_path(@issue)}/#change-#{@last_journal.id}"
    render js: "window.location = '#{ new_journal_path }'"
  end

  def destroy
    current_user = User.current

    @issue   = Issue.visible.find(params[:id])
    @project = @issue.project

    telegram_id = @issue.telegram_group.telegram_id

    @issue.telegram_group.destroy

    @issue.init_journal(current_user, I18n.t('redmine_chat_telegram.journal.chat_was_closed'))

    if @issue.save
      TelegramGroupCloseWorker.perform_async(telegram_id, current_user.id)
    end

    @last_journal = @issue.journals.visible.order("created_on").last
    redirect_to "#{issue_path(@issue)}#change-#{@last_journal.id}"
  end

end
