module Messaging
  class ConversationsController < PlatformCore::BaseController
    before_action :require_login
    before_action :set_conversation, only: :show

    def index
      @conversations = Conversation.for_participant(current_user.id).recent.limit(50)
      @unread_count = Messaging::Inbox.unread_count(current_user.id)
    end

    def show
      @conversation.mark_read_for!(current_user.id)
      @messages = @conversation.messages.limit(200)
      @message = Message.new
      @other_participant = @conversation.other_participant(current_user.id)
    end

    def new
      @conversation_start = ConversationStart.new(recipient_handle: params[:recipient])
    end

    def create
      @conversation_start = ConversationStart.new(conversation_start_params)

      if @conversation_start.save(sender_id: current_user.id)
        redirect_to conversation_path(@conversation_start.conversation), notice: "Message sent."
      else
        render :new, status: :unprocessable_content
      end
    end

    private

    def set_conversation
      @conversation = Conversation.for_participant(current_user.id).find(params[:id])
    end

    def conversation_start_params
      params.require(:messaging_conversation_start).permit(:recipient_handle, :body)
    end
  end
end
