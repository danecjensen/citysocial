FactoryBot.define do
  factory :event, class: "Events::Event" do
    sequence(:title) { |n| "Show number #{n}" }
    venue { "Mohawk" }
    category { "music" }
    starts_at { 2.days.from_now }
    score { 0.5 }
    url { "https://example.com/event" }
    image_url { "https://example.com/poster.jpg" }
  end
end
