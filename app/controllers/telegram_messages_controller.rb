class TelegramMessagesController < ApplicationController
  unloadable

  def index
    @issue = Issue.visible.find(params[:id])

    @message_count = @issue.telegram_messages.count
    @pages = Paginator.new(@message_count, per_page_option, params['page'])

    @telegram_messages =
      if params[:search].present?
        telegram_messages = Redmine::Search::Fetcher.new(params[:search], User.current, ['telegram_messages'], [@issue.project], issue_id: @issue.id, to_date: params[:to_date]).results(@pages.offset, @pages.per_page).to_a
      else
        relation = @issue.telegram_messages.limit(@pages.per_page).offset(@pages.offset)
        relation = relation.where("cast(#{TelegramMessage.table_name}.sent_at as date) <= ?", DateTime.parse(params[:to_date])) if params[:to_date].present?
        relation.to_a
      end

    @min_date = @telegram_messages.map(&:sent_at).min

    @chat_users = colored_chat_users

    respond_to do |format|
      format.html
      format.js
    end
  end

  def publish
    @issue = Issue.visible.find(params[:id])
    @telegram_messages = @issue.telegram_messages.where(id: params[:telegram_message_ids]).reverse_scope
    @issue.init_journal(User.current, @telegram_messages.as_text)
    @issue.save
    redirect_to @issue
  end

  private

  def colored_chat_users
    chat_user_ids = @telegram_messages.map(&:from_id).uniq
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
