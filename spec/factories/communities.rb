FactoryBot.define do
  factory :community, class: "Communities::Community" do
    sequence(:name) { |n| "community#{n}" }
    description { "A place to talk." }
    category { "general" }
    creator_id { create(:user).id }
  end

  factory :community_post, class: "Communities::Post" do
    community
    title { "A post worth reading" }
    body { "Some body text." }
    author_id { create(:user).id }
  end
end
