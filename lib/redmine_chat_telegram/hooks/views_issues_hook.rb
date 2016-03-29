module RedmineChatTelegram
  module Hooks
    class ViewsIssuesHook < Redmine::Hook::ViewListener
      render_on :view_issues_show_description_bottom, partial: 'issues/chat_telegram_links'
      render_on :view_issues_show_details_bottom, partial: 'issues/chat_telegram_assets'
    end
  end
end
