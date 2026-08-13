require "rails_helper"

RSpec.describe Feed::PublishPost do
  let(:author) { create(:user) }

  it "normalizes and creates URL-only posts through the canonical path" do
    result = described_class.call(
      source: " IOS-Share ",
      author_id: author.id,
      external_id: " safari-123 ",
      title: " Austin news ",
      url: " https://example.com/austin "
    )

    expect(result.status).to eq(:created)
    expect(result.post).to have_attributes(
      source: "ios-share",
      external_id: "safari-123",
      title: "Austin news",
      url: "https://example.com/austin",
      body: nil
    )
  end

  it "returns the existing post for a repeated producer identity" do
    first = described_class.call(
      source: "newsblur-cli", author_id: author.id, external_id: "story-1", body: "First copy"
    )
    duplicate = described_class.call(
      source: "newsblur-cli", author_id: author.id, external_id: "story-1", body: "Retried copy"
    )

    expect(duplicate.status).to eq(:duplicate)
    expect(duplicate.post).to eq(first.post)
    expect(Feed::Post.count).to eq(1)
    expect(duplicate.post.reload.body).to eq("First copy")
  end

  it "returns validation errors without writing incomplete posts" do
    result = described_class.call(source: "web", author_id: author.id, body: "   ")

    expect(result.status).to eq(:invalid)
    expect(result.errors).to include("title, body, or URL must be present")
    expect(Feed::Post.count).to eq(0)
  end

  it "publishes feed.post_created once, with producer attribution" do
    allow(PlatformCore::EventBus).to receive(:publish)

    described_class.call(
      source: "newsblur-cli", author_id: author.id, external_id: "story-2", body: "City hall update"
    )

    expect(PlatformCore::EventBus).to have_received(:publish).with(
      "feed.post_created",
      post_id: kind_of(Integer),
      author_id: author.id,
      source: "newsblur-cli"
    ).once
  end
end
