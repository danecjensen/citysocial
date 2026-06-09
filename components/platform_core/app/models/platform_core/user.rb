module PlatformCore
  # The single source of identity. Modules reference users by id; they do not
  # define their own user tables.
  class User < ApplicationRecord
    has_many :outgoing_follows, class_name: "PlatformCore::Follow",
             foreign_key: :follower_id, dependent: :destroy
    has_many :following, through: :outgoing_follows, source: :followed

    has_many :incoming_follows, class_name: "PlatformCore::Follow",
             foreign_key: :followed_id, dependent: :destroy
    has_many :followers, through: :incoming_follows, source: :follower

    validates :handle, presence: true, uniqueness: true
  end
end
