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

  it "finds the same PII-safe snapshot by public handle" do
    user = create(:user, handle: "neighbor", email: "private@example.com")

    profile = described_class.public_profile_by_handle("neighbor")

    expect(profile.id).to eq(user.id)
    expect(profile.handle).to eq("neighbor")
    expect(profile.to_h).not_to have_key(:email)
    expect(described_class.public_profile_by_handle("missing")).to be_nil
  end
end
