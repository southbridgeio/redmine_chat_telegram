require File.expand_path('../../../test_helper', __FILE__)
require_relative '../../../app/workers/telegram_group_close_notification_worker.rb'
require_relative '../../../app/workers/telegram_group_close_worker.rb'
require_relative '../../../app/workers/telegram_group_auto_close_worker.rb'
require 'minitest/mock'
require 'minitest/autorun'

class TelegramGroupAutoCloseWorkerTest < ActiveSupport::TestCase
  fixtures :projects, :trackers, :issues

  before do
    @closed_status = IssueStatus.create(name: 'closed', is_closed: true)
    @opened_status = IssueStatus.create(name: 'opened', is_closed: false)

    Issue.find(1).update(status_id: @opened_status.id)
    Issue.find(2).update(status_id: @closed_status.id)

    @telegram_group = RedmineChatTelegram::TelegramGroup.create(need_to_close_at: 1.day.ago,
                                                                last_notification_at: 1.day.ago,
                                                                telegram_id: 123,
                                                                issue_id: 1)
    @another_telegram_group = RedmineChatTelegram::TelegramGroup.create(need_to_close_at: 1.day.ago,
                                                                        last_notification_at: 1.day.ago,
                                                                        telegram_id: 456,
                                                                        issue_id: 2)
  end

  describe 'when close_issue_statuses setting present' do
    before do
      Setting['plugin_redmine_chat_telegram'] = { 'close_issue_statuses' => [@opened_status.id.to_s] }
    end

    it 'closes groups only for issues with required statuses' do
      mock_worker = Minitest::Mock.new.expect(:call, nil, [@telegram_group.telegram_id])

      TelegramGroupCloseWorker.stub :perform_async, mock_worker do
        TelegramGroupAutoCloseWorker.new.perform
      end

      mock_worker.verify
    end

    it 'notify only for issues with required statuses' do
      TelegramGroupCloseNotificationWorker.expects(:perform_async).with(1)
      TelegramGroupAutoCloseWorker.new.perform
    end
  end

  describe 'when close_issue_statuses settings does not present' do
    before do
      Setting['plugin_redmine_chat_telegram'] = { 'close_issue_statuses' => [] }
    end

    it 'close groups only for issues with required statuses' do
      mock_worker = Minitest::Mock.new.expect(:call, nil, [@another_telegram_group.telegram_id])

      TelegramGroupCloseWorker.stub :perform_async, mock_worker do
        TelegramGroupAutoCloseWorker.new.perform
      end

      mock_worker.verify
    end

    it 'notify only for issues with required statuses' do
      TelegramGroupCloseNotificationWorker.expects(:perform_async).with(2)
      TelegramGroupAutoCloseWorker.new.perform
    end
  end
end
