class TelegramMessagesController < ApplicationController
  unloadable


  def index
    @issue = Issue.visible.find(params[:id])
    @telegram_messages = @issue.telegram_messages

    respond_to do |format|
      format.html
      format.js
    end
  end

  def publish
    @issue = Issue.visible.find(params[:id])
    @telegram_messages = @issue.telegram_messages.where(id: params[:telegram_message_ids])
    @issue.init_journal(User.current, @telegram_messages.as_text)
    @issue.save
    redirect_to @issue
  end
end
