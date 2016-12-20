module TelegramMessagesHelper
  def messages_by_date
    @telegram_messages.group_by { |x| x.sent_at.strftime('%d.%m.%Y') }
  end

  def color_number_for_user(user_id)
    user = @chat_users.detect do |chat_user|
      chat_user[:id] == user_id
    end

    user[:color_number]
  end

  def current_date_format
    format = if Setting.date_format.empty?
               I18n.t('date.formats.default')
             else
               Setting.date_format
             end
    format.delete('%')
  end
end
