module Messaging
  class ConversationsController < PlatformCore::BaseController
    before_action :require_login
    before_action :set_conversation, only: %i[show archive restore]

    def index
      @archived = params[:view] == "archived"
      @query = params[:q].to_s.strip
      @conversations = Conversation.for_participant(current_user.id)
      @conversations = if @archived
                         @conversations.archived_for(current_user.id)
                       else
                         @conversations.active_for(current_user.id)
                       end
      if @query.present?
        matching_ids = PlatformCore::Graph.public_profile_ids_matching(@query)
        @conversations = @conversations.with_other_participant_ids(current_user.id, matching_ids)
      end
      @conversations = @conversations.recent.limit(50)
      @unread_count = Messaging::Inbox.unread_count(current_user.id)
    end

    def show
      @conversation.mark_read_for!(current_user.id)
      @messages = @conversation.messages.limit(200)
      @message = Message.new
      @other_participant = @conversation.other_participant(current_user.id)
    end

    def new
      @conversation_start = ConversationStart.new(
        recipient_handle: params[:recipient],
        context_path: params[:context_path],
        context_label: params[:context_label]
      )
    end

    def create
      @conversation_start = ConversationStart.new(conversation_start_params)

      if @conversation_start.save(sender_id: current_user.id)
        redirect_to conversation_path(@conversation_start.conversation), notice: "Message sent."
      else
        render :new, status: :unprocessable_content
      end
    end

    def archive
      @conversation.archive_for!(current_user.id)
      redirect_to conversations_path, notice: "Conversation archived."
    end

    def restore
      @conversation.restore_for!(current_user.id)
      redirect_to conversations_path(view: "archived"), notice: "Conversation restored."
    end

    private

    def set_conversation
      @conversation = Conversation.for_participant(current_user.id).find(params[:id])
    end

    def conversation_start_params
      params.require(:messaging_conversation_start).permit(:recipient_handle, :body, :context_path, :context_label)
    end
  end
end
