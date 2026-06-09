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
end
