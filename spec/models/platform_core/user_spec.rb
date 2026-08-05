require "rails_helper"

RSpec.describe PlatformCore::User, type: :model do
  it "builds a valid user from the factory" do
    expect(build(:user)).to be_valid
  end

  it "authenticates with the correct password" do
    user = create(:user, password: "right-password", password_confirmation: "right-password")
    expect(user.authenticate("right-password")).to eq(user)
    expect(user.authenticate("wrong-password")).to be_falsey
  end

  it "requires a password" do
    user = build(:user, password: nil, password_confirmation: nil)
    expect(user).not_to be_valid
  end

  it "requires a unique, well-formed email" do
    create(:user, email: "taken@example.com")
    expect(build(:user, email: "taken@example.com")).not_to be_valid
    expect(build(:user, email: "not-an-email")).not_to be_valid
  end

  it "normalizes email to lowercase and stripped" do
    user = create(:user, email: "  MixedCase@Example.COM ")
    expect(user.email).to eq("mixedcase@example.com")
  end

  it "defaults to non-admin" do
    expect(create(:user).admin?).to be(false)
  end

  it "can be an admin via the factory trait" do
    expect(create(:user, :admin).admin?).to be(true)
  end

  it "normalizes optional public profile fields and falls back to the handle" do
    user = build(:user, display_name: "  Dane Jensen  ", neighborhood: "  Hyde Park  ", bio: "  Hi, Austin!  ")

    expect(user).to be_valid
    expect(user.display_name).to eq("Dane Jensen")
    expect(user.neighborhood).to eq("Hyde Park")
    expect(user.bio).to eq("Hi, Austin!")
    expect(build(:user, display_name: nil).display_name_or_handle).to match(/user\d+/)
  end

  it "limits public profile field lengths" do
    user = build(:user, display_name: "x" * 81, neighborhood: "x" * 81, bio: "x" * 501)

    expect(user).not_to be_valid
    expect(user.errors).to include(:display_name, :neighborhood, :bio)
  end

  it "accepts image avatars and rejects other file types" do
    user = build(:user)
    user.avatar.attach(io: StringIO.new("image"), filename: "avatar.png", content_type: "image/png")
    expect(user).to be_valid

    user.avatar.attach(io: StringIO.new("document"), filename: "avatar.pdf", content_type: "application/pdf")
    expect(user).not_to be_valid
    expect(user.errors[:avatar]).to include("must be a JPEG, PNG, or WebP image")
  end
  it "rejects avatars larger than five megabytes" do
    user = build(:user)
    oversized = "x" * (PlatformCore::User::AVATAR_MAX_SIZE + 1)
    user.avatar.attach(io: StringIO.new(oversized), filename: "avatar.png", content_type: "image/png")

    expect(user).not_to be_valid
    expect(user.errors[:avatar]).to include("must be smaller than 5 MB")
  end
end
