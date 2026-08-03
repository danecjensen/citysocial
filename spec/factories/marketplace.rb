FactoryBot.define do
  factory :listing, class: "Marketplace::Listing" do
    author_id { create(:user).id }
    sequence(:title) { |n| "Great item number #{n}" }
    category { "for_sale_other" }
    condition { "good" }
    price { 25 }
    location { "East Austin" }
    description { "In good shape." }
  end
end
