require "rails_helper"

RSpec.describe PlatformCore::Graph do
  it "exposes a public profile snapshot without private identity fields" do
    user = create(
      :user,
      display_name: "Dane Jensen",
      neighborhood: "Hyde Park",
      bio: "Austin neighbor.",
      email: "private@example.com"
    )

    profile = described_class.public_profile(user.id)

    expect(profile.to_h).to include(
      id: user.id,
      handle: user.handle,
      display_name: "Dane Jensen",
      neighborhood: "Hyde Park",
      bio: "Austin neighbor.",
      avatar_attached: false
    )
    expect(profile.to_h).not_to have_key(:email)
    expect(profile.to_h).not_to have_key(:password_digest)
  end

  it "batch-loads users into an id-keyed hash, ignoring blank and unknown ids" do
    a = create(:user)
    b = create(:user)

    result = described_class.users([a.id, b.id, a.id, nil, "", 0])

    expect(result.keys).to contain_exactly(a.id, b.id)
    expect(result[a.id]).to eq(a)
    expect(result[b.id]).to eq(b)
    expect(described_class.users([])).to eq({})
  end

  it "finds the same PII-safe snapshot by public handle" do
    user = create(:user, handle: "neighbor", email: "private@example.com")

    profile = described_class.public_profile_by_handle("neighbor")

    expect(profile.id).to eq(user.id)
    expect(profile.handle).to eq("neighbor")
    expect(profile.to_h).not_to have_key(:email)
    expect(described_class.public_profile_by_handle("missing")).to be_nil
  end

  it "finds public profile ids by handle or display name without returning identity records" do
    handle_match = create(:user, handle: "eastside_neighbor", display_name: "Taylor")
    name_match = create(:user, handle: "runner", display_name: "Helpful Neighbor")
    create(:user, handle: "unrelated", display_name: "Someone Else")

    expect(described_class.public_profile_ids_matching("neighbor")).to match_array(
      [handle_match.id, name_match.id]
    )
    expect(described_class.public_profile_ids_matching("HELPFUL")).to eq([name_match.id])
    expect(described_class.public_profile_ids_matching(" ")).to eq([])
  end
end
