module Messaging
  class MessagesController < PlatformCore::BaseController
    before_action :require_login

    def create
      @conversation = Conversation.for_participant(current_user.id).find(params[:conversation_id])
      @message = @conversation.messages.new(message_params.merge(sender_id: current_user.id))

      if @message.save
        redirect_to conversation_path(@conversation), notice: "Reply sent."
      else
        @conversation.mark_read_for!(current_user.id)
        @messages = @conversation.messages.reject(&:new_record?)
        @other_participant = @conversation.other_participant(current_user.id)
        render "messaging/conversations/show", status: :unprocessable_content
      end
    end

    private

    def message_params
      params.require(:message).permit(:body)
    end
  end
end
