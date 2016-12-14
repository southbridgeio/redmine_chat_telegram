module RedmineChatTelegram
  class IssueUpdater

    attr_reader :issue, :user

    def initialize(issue, user)
      @issue = issue
      @user = user
    end

    def call(params)
      params.stringify_keys!
      User.current = user
      issue.init_journal(user)
      issue.safe_attributes = params
      if issue.save
        issue.current_journal
      else
        nil
      end
    end
  end
end
