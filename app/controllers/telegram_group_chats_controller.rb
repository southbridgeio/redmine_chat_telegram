class TelegramGroupChatsController < ApplicationController
  unloadable

  def create
    current_user = User.current

    @issue = Issue.visible.find(params[:issue_id])

    RedmineChatTelegram::GroupChatCreator.new(@issue, current_user).run

    @project = @issue.project

    @last_journal    = @issue.journals.visible.order('created_on').last
    new_journal_path = "#{issue_path(@issue)}/#change-#{@last_journal.id}"
    render js: "window.location = '#{new_journal_path}'"
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

    @last_journal = @issue.journals.visible.order('created_on').last
    redirect_to "#{issue_path(@issue)}#change-#{@last_journal.id}"
  end
end
