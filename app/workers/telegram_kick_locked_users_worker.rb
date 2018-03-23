class TelegramKickLockedUsersWorker
  include Sidekiq::Worker
  include TelegramCommon::Tdlib::DependencyProviders::Client

  def perform
    return unless Setting.plugin_redmine_chat_telegram['kick_locked']
    client.on_ready(&method(:kick_locked_users))
  end

  private

  def kick_locked_users(client)
    RedmineChatTelegram::TelegramGroup.all.each do |group|
      chat = client.broadcast_and_receive('@type' => 'getChat', 'chat_id' => group.telegram_id)

      telegram_user_ids = client.broadcast_and_receive('@type' => 'getBasicGroupFullInfo',
                                     'basic_group_id' => chat.dig('type', 'basic_group_id')
                          )['members'].map { |m| m['user_id'] }

      User.where(telegram_id: telegram_user_ids).each do |user|
        next unless user.locked?
        result = client.broadcast_and_receive('@type' => 'setChatMemberStatus',
                                    'chat_id' => group.telegram_id,
                                    'user_id' => user.telegram_id,
                                    'status' => { '@type' => 'chatMemberStatusLeft' })
        logger.debug("Kicked user ##{user.id} from chat ##{group.telegram_id}") if result['@type'] == 'ok'
        logger.error("Failed to kick user ##{user.id} from chat ##{group.telegram_id}: #{result.inspect}") if result['@type'] == 'ok'
      end
    end
  ensure
    client.close
  end

  def logger
    @logger ||= Logger.new(Rails.root.join('log/chat_telegram',
                                           'telegram-kick-locked-users.log'))
  end
end
