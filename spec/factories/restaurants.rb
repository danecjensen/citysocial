FactoryBot.define do
  factory :restaurant, class: "Restaurants::Restaurant" do
    sequence(:name) { |n| "Restaurant #{n}" }
    cuisine { "Tacos" }
    area { "East Austin" }
  end
end
