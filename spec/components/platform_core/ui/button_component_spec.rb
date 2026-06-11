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
end
