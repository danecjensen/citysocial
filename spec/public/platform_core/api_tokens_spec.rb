require "rails_helper"

RSpec.describe PlatformCore::ApiTokens do
  let(:user) { create(:user) }

  it "issues a source-scoped secret while persisting only its digest" do
    issued = described_class.issue!(source: "NewsBlur-CLI", user_id: user.id)
    stored = PlatformCore::ApiToken.find(issued.id)

    expect(issued.token).to start_with("cs_ingest_")
    expect(issued.source).to eq("newsblur-cli")
    expect(stored.token_digest).not_to eq(issued.token)
    expect(stored).to have_attributes(source: "newsblur-cli", user_id: user.id)
  end

  it "authenticates active secrets, records use, and rejects revoked secrets" do
    issued = described_class.issue!(source: "ios-share", user_id: user.id)

    credential = described_class.authenticate(issued.token)

    expect(credential).to have_attributes(source: "ios-share", user_id: user.id)
    expect(PlatformCore::ApiToken.find(issued.id).last_used_at).to be_present

    described_class.revoke!(issued.id)
    expect(described_class.authenticate(issued.token)).to be_nil
  end

  it "rejects unknown secrets" do
    expect(described_class.authenticate("cs_ingest_not-a-real-token")).to be_nil
  end
end
