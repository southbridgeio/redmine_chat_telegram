class TelegramGroupHistoryUpdateWorker
  include Sidekiq::Worker
  include ActionView::Helpers::DateHelper

  TELEGRAM_GROUP_HISTORY_UPDATE_LOG = Logger.new(Rails.root.join('log/chat_telegram',
                                                                 'telegram-group-history-update.log'))

  CHAT_HISTORY_PAGE_SIZE = 100

  def perform
    I18n.locale = Setting['default_language']

    RedmineChatTelegram::TelegramGroup.find_each do |telegram_group|
      issue = telegram_group.issue

      present_message_ids = issue.telegram_messages.pluck(:telegram_id)

      bot_ids = [Setting.plugin_redmine_chat_telegram['bot_id'].to_i,
                 Setting.plugin_redmine_chat_telegram['robot_id'].to_i]

      telegram_group = issue.telegram_group
      telegram_id    = telegram_group.telegram_id.abs

      TELEGRAM_GROUP_HISTORY_UPDATE_LOG.debug "chat##{telegram_id}"

      chat_name         = "chat##{telegram_id.abs}"
      page              = 0
      has_more_messages = create_new_messages(issue.id, chat_name, bot_ids, present_message_ids, page)

      while has_more_messages do
        page              += 1
        has_more_messages = create_new_messages(issue.id, chat_name, bot_ids, present_message_ids, page)
      end
    end
  rescue ActiveRecord::RecordNotFound => e
    # ignore
  end

  def create_new_messages(issue_id, chat_name, bot_ids, present_message_ids, page)

    cmd = "history #{chat_name} #{CHAT_HISTORY_PAGE_SIZE} #{CHAT_HISTORY_PAGE_SIZE * page}"

    json_messages = RedmineChatTelegram.run_cli_command(cmd, TELEGRAM_GROUP_HISTORY_UPDATE_LOG)

    new_json_messages = json_messages.select do |message|
      from = message['from']

      from.present? and
          not present_message_ids.include?(message['id']) and

          not bot_ids.include?(from['id'])
    end

    new_json_messages.each do |message|
      message_id = message['id']
      sent_at    = Time.at message['date']

      from            = message['from']
      from_id         = from['id']
      from_first_name = from['first_name']
      from_last_name  = from['last_name']
      from_username   = from['username']

      TelegramMessage.where(telegram_id: message_id).first_or_create issue_id:        issue_id,
                                                                     sent_at:         sent_at,
                                                                     from_id:         from_id,
                                                                     from_first_name: from_first_name,
                                                                     from_last_name:  from_last_name,
                                                                     from_username:   from_username
    end
    json_messages.size == CHAT_HISTORY_PAGE_SIZE
  end
end
