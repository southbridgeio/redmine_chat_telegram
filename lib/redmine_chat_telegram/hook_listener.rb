class ChatHookListener < Redmine::Hook::ViewListener
  render_on :view_issues_show_details_bottom, partial: 'telegram_group_chats/link_or_button'
  render_on :view_issues_show_description_bottom, partial: 'telegram_group_chats/link_or_button'
  render_on :view_issues_sidebar_issues_bottom, partial: 'telegram_group_chats/link_or_button'
  render_on :view_issues_sidebar_planning_bottom, partial: 'telegram_group_chats/link_or_button'
  render_on :view_issues_sidebar_queries_bottom, partial: 'telegram_group_chats/link_or_button'
end
