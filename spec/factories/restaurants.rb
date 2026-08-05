FactoryBot.define do
  factory :restaurant, class: "Restaurants::Restaurant" do
    sequence(:name) { |n| "Restaurant #{n}" }
    cuisine { "Tacos" }
    area { "East Austin" }

    trait :with_photo do
      after(:build) do |restaurant|
        restaurant.photos.attach(
          io: StringIO.new(TestImages.png_1x1),
          filename: "hero.png",
          content_type: "image/png"
        )
      end
    end
  end
end

# Tiny valid 1x1 PNG so Active Storage attachment specs don't need real files.
module TestImages
  module_function

  def png_1x1
    Base64.decode64(
      "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
    )
  end
end
