class TelegramMessagesController < ApplicationController
  unloadable


  def index
    @issue = Issue.visible.find(params[:id])
    @telegram_messages = @issue.telegram_messages
    @chat_users = colored_chat_users

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

  private

  def colored_chat_users
    chat_user_ids = @telegram_messages.select(:from_id).uniq.pluck(:from_id)
    colored_users = []
    current_color = 1

    chat_user_ids.each do |user_id|
      current_color = 1 if current_color > TelegramMessage::COLORS_NUMBER
      colored_users << { id: user_id, color_number: current_color }
      current_color += 1
    end

    colored_users
  end
end
