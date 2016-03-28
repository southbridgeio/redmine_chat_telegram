module TelegramMessagesHelper

  def messages_by_date
    @telegram_messages.group_by{|x| x.sent_at.strftime("%d.%m.%Y")}
  end

end
