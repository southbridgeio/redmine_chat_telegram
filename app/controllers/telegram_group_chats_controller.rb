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

    RedmineChatTelegram::GroupChatDestroyer.new(@issue, current_user).run

    @last_journal = @issue.journals.visible.order('created_on').last
    redirect_to "#{issue_path(@issue)}#change-#{@last_journal.id}"
  end
end
