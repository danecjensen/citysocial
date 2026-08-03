require "rails_helper"

RSpec.describe Communities::Community, type: :model do
  it "slugifies the name and makes the creator an owner member" do
    creator = create(:user)
    community = described_class.create!(name: "EastAustin", creator_id: creator.id)

    expect(community.slug).to eq("eastaustin")
    expect(community.to_param).to eq("eastaustin")
    expect(community.members_count).to eq(1)
    expect(community.role_for(creator.id)).to eq("owner")
  end

  it "validates the name format and uniqueness" do
    create(:community, name: "dupe")
    expect(build(:community, name: "dupe")).not_to be_valid
    expect(build(:community, name: "has spaces")).not_to be_valid
    expect(build(:community, name: "ok")).not_to be_valid # too short (min 3)
  end

  it "joins and leaves, but owners cannot leave" do
    community = create(:community)
    owner_id = community.creator_id
    member = create(:user)

    community.join!(member.id)
    expect(community.member?(member.id)).to be(true)
    expect(community.members_count).to eq(2)

    expect(community.leave!(member.id)).to be(true)
    expect(community.members_count).to eq(1)
    expect(community.leave!(owner_id)).to be(false)
  end

  it "publishes communities.community_created" do
    events = []
    PlatformCore::EventBus.subscribe("communities.community_created", ->(_name, payload) { events << payload })

    community = create(:community)

    expect(events.last).to include(community_id: community.id, creator_id: community.creator_id)
  end
end
