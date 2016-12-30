module RedmineChatTelegram
  class IssueUpdater

    attr_reader :issue, :user

    def initialize(issue, user)
      @issue = issue
      @user = user
      User.current = user
    end

    def call(params)
      @params = params
      prepare_params

      issue.init_journal(user)
      issue.safe_attributes = @params
      if issue.save
        issue.current_journal
      else
        nil
      end
    end

    private

    def prepare_params
      @params.stringify_keys!
      find_project if @params["project"].present?
      find_tracker if @params["tracker"].present?
      find_status if @params["status"].present?
      find_priority if @params["priority"].present?
      find_assigned_to if @params["assigned_to"].present?
      format_date if @params["start_date"].present? || @params["due_date"].present?
      @params.compact!
    end

    def format_date
      @params["start_date"] = Date.parse(@params["start_date"], "%d.%m.%Y").to_s rescue nil
      @params["due_date"] = Date.parse(@params["due_date"], "%d.%m.%Y").to_s rescue nil
    end

    def find_project
      project = Project.visible
        .where("identifier = :project OR name = :project", project: @params["project"]).first
      @params["project_id"] = project&.id
    end

    def find_tracker
      tracker = Tracker.where('lower(name) = ?', @params["tracker"].mb_chars.downcase).try(:first)
      @params["tracker_id"] = tracker&.id
    end

    def find_status
      status = IssueStatus.where('lower(name) = ?', @params["status"].mb_chars.downcase).try(:first)
      @params["status_id"] = status&.id
    end

    def find_priority
      priority = IssuePriority.where('lower(name) = ?', @params["priority"].mb_chars.downcase).try(:first)
      @params["priority_id"] = priority&.id
    end

    def find_assigned_to
      assigned_to = User.find_by(login: @params["assigned_to"])
      @params["assigned_to_id"] = assigned_to&.id
    end
  end
end
