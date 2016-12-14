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
      issue.save
    end
  end
end
