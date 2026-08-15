FactoryBot.define do
  factory :shared_calendar_event, class: "SharedCalendar::Event" do
    transient do
      author { association(:user) }
    end

    author_id { author.id }
    sequence(:title) { |n| "Community event #{n}" }
    category { "community" }
    starts_at { 2.days.from_now.change(min: 0) }
    ends_at { starts_at + 2.hours }
    venue_name { "Republic Square" }
    location { "Downtown Austin" }

    trait :with_image do
      after(:build) do |event|
        event.image.attach(
          io: StringIO.new(TestImages.png_1x1),
          filename: "event.png",
          content_type: "image/png"
        )
      end
    end
  end
end
