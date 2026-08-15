require "rails_helper"

RSpec.describe Feed::FetchLinkPreview do
  it "extracts article metadata and verifies the lead image bytes" do
    page = described_class::Response.new(
      body: <<~HTML,
        <html><head>
          <meta property="og:title" content="City council approves new park">
          <meta property="og:description" content="A useful local summary.">
          <meta property="og:site_name" content="Austin Daily">
          <meta property="og:image" content="/lead.png">
        </head></html>
      HTML
      content_type: "text/html",
      uri: URI("https://news.example/story")
    )
    image = described_class::Response.new(
      body: TestImages.png_1x1,
      content_type: "image/png",
      uri: URI("https://news.example/lead.png")
    )
    fetcher = described_class.new
    allow(fetcher).to receive(:fetch).and_return(page, image)

    preview = fetcher.call("https://news.example/story")

    expect(preview).to have_attributes(
      title: "City council approves new park",
      description: "A useful local summary.",
      site_name: "Austin Daily",
      image_content_type: "image/png",
      image_filename: "article-preview.png"
    )
    expect(preview.image_io.read).to eq(TestImages.png_1x1)
  end

  it "refuses private-network URLs before making a request" do
    allow(Resolv).to receive(:getaddresses).with("internal.example").and_return(["127.0.0.1"])

    expect { described_class.call("http://internal.example/admin") }
      .to raise_error(Feed::FetchLinkPreview::Error, /private network/)
  end

  it "also refuses IPv4-mapped private addresses" do
    allow(Resolv).to receive(:getaddresses).with("mapped.example").and_return(["::ffff:127.0.0.1"])

    expect { described_class.call("http://mapped.example/admin") }
      .to raise_error(Feed::FetchLinkPreview::Error, /private network/)
  end
end
