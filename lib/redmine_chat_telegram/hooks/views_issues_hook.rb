module RedmineChatTelegram
  module Hooks
    class ViewsIssuesHook < Redmine::Hook::ViewListener
      render_on :view_issues_show_description_bottom, partial: 'telegram_group_chats/link_or_button'
    end
  end
end
