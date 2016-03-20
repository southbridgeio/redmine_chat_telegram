class ChatHookListener < Redmine::Hook::ViewListener
  render_on :view_issues_show_details_bottom, partial: 'telegram_group_chats/link_or_button'
end
