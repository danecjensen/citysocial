require "rails_helper"

RSpec.describe PlatformCore::Ui::ButtonComponent do
  it "renders a submit button by default" do
    render_inline(described_class.new) { "Save" }

    expect(page).to have_css("button[type=submit]", text: "Save")
    expect(page).to have_css("button.bg-brand-600")
  end

  it "renders an anchor when given href" do
    render_inline(described_class.new(variant: :secondary, href: "/somewhere")) { "Go" }

    expect(page).to have_css("a[href='/somewhere']", text: "Go")
    expect(page).to have_no_css("a[target], a[rel]")
  end

  it "passes target and rel through to link buttons" do
    render_inline(described_class.new(href: "https://example.com", target: "_blank", rel: "noopener noreferrer")) do
      "External"
    end

    expect(page).to have_css(
      "a[href='https://example.com'][target='_blank'][rel='noopener noreferrer']",
      text: "External"
    )
  end

  it "renders a button_to form when given href and method" do
    render_inline(described_class.new(variant: :danger, href: "/things/1", method: :delete, confirm: "Sure?")) do
      "Delete"
    end

    expect(page).to have_css("form[action='/things/1'] button[data-turbo-confirm='Sure?']", text: "Delete")
  end

  it "rejects unknown variants" do
    expect { described_class.new(variant: :sparkly) }.to raise_error(KeyError)
  end

  it "renders an aria-label on a plain button" do
    render_inline(described_class.new(aria_label: "Upvote")) { "▲" }

    expect(page).to have_css("button[aria-label='Upvote']")
  end

  it "renders an aria-label on a link button" do
    render_inline(described_class.new(href: "/somewhere", aria_label: "Upvote")) { "▲" }

    expect(page).to have_css("a[href='/somewhere'][aria-label='Upvote']")
  end

  it "renders an aria-label on a button_to button" do
    render_inline(described_class.new(href: "/vote", method: :post, aria_label: "Upvote")) { "▲" }

    expect(page).to have_css("form[action='/vote'] button[aria-label='Upvote']")
  end

  it "omits the aria-label attribute when none is given" do
    render_inline(described_class.new) { "Save" }

    expect(page).to have_no_css("button[aria-label]")
  end

  it "renders aria-pressed=true for a pressed toggle button" do
    render_inline(described_class.new(href: "/vote", method: :post, aria_label: "Upvote", pressed: true)) { "▲" }

    expect(page).to have_css("button[aria-pressed='true']")
  end

  it "renders aria-pressed=false for an unpressed toggle button" do
    render_inline(described_class.new(href: "/vote", method: :post, aria_label: "Upvote", pressed: false)) { "▲" }

    expect(page).to have_css("button[aria-pressed='false']")
  end

  it "omits aria-pressed when pressed is not given" do
    render_inline(described_class.new) { "Save" }

    expect(page).to have_no_css("button[aria-pressed]")
  end
end
