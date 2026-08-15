module Communities
  class Community < ApplicationRecord
    CATEGORIES = %w[general housing jobs buy_sell services events gigs].freeze

    has_many :memberships, class_name: "Communities::Membership", dependent: :destroy
    has_many :posts, class_name: "Communities::Post", dependent: :destroy

    validates :name, presence: true, uniqueness: { case_sensitive: false },
                     length: { minimum: 3, maximum: 50 },
                     format: { with: /\A[a-zA-Z0-9_]+\z/, message: "only letters, numbers, and underscores" }
    validates :description, length: { maximum: 1000 }, allow_blank: true
    validates :category, inclusion: { in: CATEGORIES }, allow_blank: true

    before_validation :set_slug, on: :create
    after_create :seed_owner_membership
    after_create_commit :announce_creation

    scope :popular, -> { order(members_count: :desc, created_at: :desc) }
    scope :recent, -> { order(created_at: :desc) }

    def to_param
      slug
    end

    # Identity is owned by the kernel; read the creator through its public API.
    def creator
      PlatformCore::Graph.user(creator_id)
    end

    def member?(user_id)
      return false unless user_id

      memberships.exists?(user_id: user_id)
    end

    def role_for(user_id)
      return nil unless user_id

      memberships.find_by(user_id: user_id)&.role
    end

    def join!(user_id)
      membership = memberships.find_or_create_by!(user_id: user_id) { |m| m.role = :member }
      recount_members!
      membership
    end

    # Mirrors join! as a mutating action; returns whether the leave succeeded.
    def leave!(user_id) # rubocop:disable Naming/PredicateMethod
      membership = memberships.find_by(user_id: user_id)
      return false if membership.nil? || membership.owner?

      membership.destroy
      recount_members!
      true
    end

    private

    def set_slug
      self.slug ||= name.to_s.downcase
    end

    def seed_owner_membership
      memberships.create!(user_id: creator_id, role: :owner)
      recount_members!
    end

    def recount_members!
      update_column(:members_count, memberships.count)
    end

    def announce_creation
      PlatformCore::EventBus.publish(
        "communities.community_created",
        community_id: id,
        creator_id: creator_id,
        target_path: "/communities/#{slug}"
      )
    end
  end
end
