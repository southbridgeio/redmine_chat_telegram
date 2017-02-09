module RedmineChatTelegram
  class Bot
    module GroupCommand
      include IssuesHelper
      include ActionView::Helpers::TagHelper
      include ERB::Util
      private

      def group_common_commands
        %w(help)
      end

      def group_plugin_commands
        %w(task link url log subject start_date due_date estimated_hours done_ratio project tracker status priority assigned_to subject_chat)
      end

      def group_ext_commands
        []
      end

      def group_commands
        (group_common_commands +
          group_plugin_commands +
          group_ext_commands
        ).uniq
      end

      attr_reader :message

      def handle_group_command
        if !group_commands.include?(command_name) && command_name.present?
          if private_commands.include?(command_name)
            send_message(I18n.t('telegram_common.bot.group.private_command'))
          else
            send_message(I18n.t('redmine_chat_telegram.bot.command_not_found'))
          end
        else
          if group_common_command?
            execute_group_command
          else
            handle_group_message
          end
        end
      end

      def group_common_command?
        group_common_commands.include?(command_name)
      end

      def handle_group_message
        @issue = find_issue
        return unless issue.present?

        init_message

        if command.group_chat_created
          group_chat_created

        elsif command.new_chat_member.present?
          new_chat_member

        elsif command.left_chat_member.present?
          left_chat_member

        elsif command.text =~ /\/task|\/link|\/url/
          send_issue_link

        elsif command.text =~ /\/log/
          log_message

        elsif command.text =~ %r{/subject|/start_date|/due_date|/estimated_hours|/done_ratio|/project|/tracker|/status|/priority|/assigned_to}
          if com = command.text.match(%r{^/subject$|^/start_date$|^/due_date$|/^estimated_hours$
              |^/done_ratio$|^/project$|^/tracker$|^/status$|^/assigned_to$|^/priority$})
            send_current_value(com[0][1..-1])
          else
            change_issue
          end

        elsif command.text.present?
          save_message
        end
      end

      def find_issue
        chat_id = command.chat.id

        begin
          Issue.joins(:telegram_group)
            .find_by!(redmine_chat_telegram_telegram_groups: { telegram_id: chat_id.abs })
        rescue ActiveRecord::RecordNotFound => e
          nil
        end
      end

      def init_message
        @message = TelegramMessage.new(
          issue_id: issue.id,
          telegram_id: command.message_id,
          sent_at: Time.at(command.date),
          from_id: command.from.id,
          from_first_name: command.from.first_name,
          from_last_name: command.from.last_name,
          from_username: command.from.username,
          is_system: true,
          bot_message: true)
      end

      def group_chat_created
        issue_url = RedmineChatTelegram.issue_url(issue.id)
        send_message(I18n.t('redmine_chat_telegram.messages.hello', issue_url: issue_url))

        message.message = 'chat_was_created'
        message.save!
      end

      def new_chat_member
        new_chat_member = command.new_chat_member

        if command.from.id == new_chat_member.id
          message.message = 'joined'
        else
          message.message = 'invited'
          message.system_data = chat_user_full_name(new_chat_member)
        end

        message.save!
      end

      def left_chat_member
        left_chat_member = command.left_chat_member

        if command.from.id == left_chat_member.id
          message.message = 'left_group'
        else
          message.message = 'kicked'
          message.system_data = chat_user_full_name(left_chat_member)
        end

        message.save!
      end

      def send_issue_link
        return unless can_access_issue?

        issue_url = RedmineChatTelegram.issue_url(issue.id)
        issue_url_text = "<a href='#{issue_url}'>##{issue.id}</a> <b>#{issue.subject}</b>"
        issue_url_text << "\n#{I18n.t('field_assigned_to')}: #{issue.assigned_to}" if issue.assigned_to.present?
        issue_url_text << "\n#{I18n.t('field_priority')}: #{issue.priority}"
        issue_url_text << "\n#{I18n.t('field_status')}: #{issue.status}"
        send_message(issue_url_text)
      end

      def log_message
        return unless can_access_issue?

        message.message = command.text.gsub(/\/log\s|\s\/log$/, '')
        message.bot_message = false
        message.is_system = false

        journal_text = message.as_text(with_time: false)
        issue.init_journal(
          User.anonymous,
          "_#{I18n.t('redmine_chat_telegram.journal.from_telegram')}:_ \n\n#{journal_text}")

        issue.save!
        message.save!
      end

      def change_issue
        return unless can_edit_issue?
        params = command.text.match(/\/(\w+) (.+)/)
        return send_error unless params.present?
        attr = params[1]
        value = params[2]
        return change_issue_chat_name(value) if attr == 'subject_chat'
        journal = IssueUpdater.new(@issue, redmine_user).call(attr => value)
        if journal.present? && journal.details.any?
          message = details_to_strings(journal.details).join("\n")
          send_message(message)
        else
          send_error
        end
      end

      def change_issue_chat_name(name)
        chat_name = "chat##{issue.telegram_group.telegram_id.abs}"
        cmd = "rename_chat #{chat_name} #{name}"
        RedmineChatTelegram.socket_cli_command(cmd, logger)
      end

      def send_current_value(command)
        send_message("#{command.capitalize}: #{issue.send(command).to_s}")
      end

      def send_error
        send_message(I18n.t('redmine_chat_telegram.bot.error_editing_issue'))
      end

      def save_message
        message.message = command.text
        message.bot_message = false
        message.is_system = false
        message.save!
      end

      def chat_user_full_name(telegram_user)
        [telegram_user.first_name, telegram_user.last_name].compact.join ' '
      end

      def redmine_user
        @redmine_user ||= TelegramCommon::Account.find_by!(telegram_id: command.from.id).try(:user)
      rescue ActiveRecord::RecordNotFound
        nil
      end

      def can_edit_issue?
        can_access_issue? && redmine_user.allowed_to?(:edit_issues, issue.project)
      end

      def can_access_issue?
        if redmine_user.present? && issue.present? && redmine_user.allowed_to?(:view_issues, issue.project)
          true
        else
          send_message(I18n.t('redmine_chat_telegram.bot.access_denied'))
          false
        end
      end
    end
  end
end
