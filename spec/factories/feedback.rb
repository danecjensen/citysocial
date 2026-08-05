FactoryBot.define do
  factory :feedback_submission, class: "Feedback::Submission" do
    author_id { create(:user).id }
    kind { "idea" }
    status { "open" }
    area { "feed" }
    sequence(:title) { |n| "A useful product idea #{n}" }
    description { "This change would make the product much easier to use every day." }
  end
end
