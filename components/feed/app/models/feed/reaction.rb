module Feed
  class Reaction < ApplicationRecord
    KINDS = %w[like celebrate helpful].freeze

    belongs_to :post, class_name: "Feed::Post", counter_cache: true, inverse_of: :reactions

    validates :user_id, :kind, presence: true
    validates :kind, inclusion: { in: KINDS }
    validates :user_id, uniqueness: { scope: :post_id }
  end
end
