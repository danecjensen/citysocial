FactoryBot.define do
  factory :notification, class: "Notifications::Notification" do
    transient do
      recipient { association(:user) }
      actor { association(:user) }
    end

    recipient_id { recipient.id }
    actor_id { actor.id }
    event_name { "feed.post_created" }
    sequence(:source_id)
    message { "@#{actor.handle} shared a feed post." }
    target_path { "/feed" }
  end
end
