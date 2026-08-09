FactoryBot.define do
  factory :neighbor_help_request, class: "NeighborHelp::Request" do
    transient do
      requester { association(:user) }
    end

    requester_id { requester.id }
    sequence(:title) { |n| "Small neighbor favor #{n}" }
    details { "Meet at the library help desk to configure a new phone." }
    category { "tech_help" }
    neighborhood { "North Loop" }
    starts_at { 1.day.from_now }
    ends_at { 1.day.from_now + 2.hours }
    estimated_minutes { 45 }
    logistics_notes { "Coordinate the public meeting point after a helper claims it." }
    no_cash_confirmed { true }
  end

  factory :neighbor_help_report, class: "NeighborHelp::Report" do
    association :request, factory: :neighbor_help_request
    reporter_id { create(:user).id }
    reason { "unsafe_scope" }
    details { "This request appears outside the bounded favor rules." }
  end
end
