FactoryBot.define do
  factory :pickup_sports_game_series, class: "PickupSports::GameSeries" do
    transient do
      host { association(:user) }
    end

    host_id { host.id }
    sequence(:title) { |n| "Weekly pickup series #{n}" }
    sport { "soccer" }
    skill_level { "all_levels" }
    neighborhood { "East Austin" }
    venue { "Pan Am Park" }
    details { "Bring water. Newcomers are welcome." }
    starts_at { 2.days.from_now }
    capacity { 12 }
    occurrences_count { 4 }
  end

  factory :pickup_sports_game, class: "PickupSports::Game" do
    transient do
      host { association(:user) }
    end

    host_id { host.id }
    sequence(:title) { |n| "Saturday pickup game #{n}" }
    sport { "soccer" }
    skill_level { "all_levels" }
    neighborhood { "East Austin" }
    venue { "Pan Am Park" }
    details { "Bring water. Newcomers are welcome." }
    starts_at { 2.days.from_now }
    capacity { 12 }
  end

  factory :pickup_sports_roster_entry, class: "PickupSports::RosterEntry" do
    association :game, factory: :pickup_sports_game
    resident_id { create(:user).id }
    status { "joined" }
  end
end
