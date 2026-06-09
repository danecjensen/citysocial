FactoryBot.define do
  factory :user, class: "PlatformCore::User" do
    sequence(:handle) { |n| "user#{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "s3cret-password" }
    password_confirmation { "s3cret-password" }

    trait :admin do
      admin { true }
    end
  end
end
