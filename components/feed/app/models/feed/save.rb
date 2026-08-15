module Feed
  class Save < ApplicationRecord
    belongs_to :post, class_name: "Feed::Post", counter_cache: true, inverse_of: :saves

    validates :user_id, presence: true, uniqueness: { scope: :post_id }
  end
end
