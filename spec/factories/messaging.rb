FactoryBot.define do
  factory :messaging_conversation, class: "Messaging::Conversation" do
    transient do
      first_participant { association(:user) }
      second_participant { association(:user) }
    end

    first_participant_id { first_participant.id }
    second_participant_id { second_participant.id }
  end

  factory :messaging_message, class: "Messaging::Message" do
    association :conversation, factory: :messaging_conversation
    sender_id { conversation.first_participant_id }
    body { "Want to meet at the neighborhood market?" }
  end
end
