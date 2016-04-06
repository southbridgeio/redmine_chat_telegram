class TelegramGroupChatsController < ApplicationController
  unloadable

  helper :journals
  helper :issues

  def create
    current_user = User.current

    cli_path        = REDMINE_CHAT_TELEGRAM_CONFIG['telegram_cli_path']
    public_key_path = REDMINE_CHAT_TELEGRAM_CONFIG['telegram_cli_public_key_path']
    cli_base        = "#{cli_path} -WCI -k #{public_key_path} -e "

    @issue = Issue.visible.find(params[:issue_id])

    subject  = "#{@issue.project.name} ##{@issue.id}"
    bot_name = Setting.plugin_redmine_chat_telegram['bot_name']

    result      = %x(#{cli_base} "create_group_chat \\"#{subject}\\" #{bot_name}" )
    telegram_id = result.match(/chat#(\d+)/)[1].to_i
    chat_id     = result.match(/chat#(\d+)/).to_s

    cmd    = "#{cli_base} \"export_chat_link #{chat_id}\""
    result = %x( #{cmd} )

    telegram_chat_url = result.match(/https:\/\/telegram.me\/joinchat\/[\w-]+/).to_s

    if @issue.telegram_group.present?
      @issue.telegram_group.update shared_url: telegram_chat_url
    else
      @issue.create_telegram_group telegram_id: telegram_id,
                                   shared_url:  telegram_chat_url
    end

    @issue.init_journal(current_user,
                        I18n.t('redmine_chat_telegram.journal.chat_was_created',
                               telegram_chat_url: telegram_chat_url))
    @issue.save

    @project = @issue.project

    load_journals

    respond_to do |format|
      format.html { redirect_to @issue }
      format.js
    end
  end

  def destroy
    @issue   = Issue.visible.find(params[:id])
    @project = @issue.project

    @issue.telegram_group.destroy
    @issue.init_journal(user, I18n.t('redmine_chat_telegram.journal.chat_was_closed'))

    if @issue.save
      TelegramGroupCloseWorker.perform_async(@issue.id, User.current.id)
    end
  end

  private

  def load_journals
    @journals = @issue.journals.includes(:user, :details).
        references(:user, :details).
        reorder(:created_on, :id).to_a
    @journals.each_with_index { |j, i| j.indice = i+1 }
    @journals.reject!(&:private_notes?) unless User.current.allowed_to?(:view_private_notes, @issue.project)
    Journal.preload_journals_details_custom_fields(@journals)
    @journals.select! { |journal| journal.notes? || journal.visible_details.any? }
    @journals.reverse! if User.current.wants_comments_in_reverse_order?
  end
end
