require "rails_helper"

RSpec.describe PlatformCore::Ui::FlashComponent do
  it "styles notice as success" do
    render_inline(described_class.new(type: :notice, message: "Welcome"))

    expect(page).to have_css("div.bg-success-soft[role=status]", text: "Welcome")
  end

  it "styles error as danger" do
    render_inline(described_class.new(type: "error", message: "Nope"))

    expect(page).to have_css("div.bg-danger-soft", text: "Nope")
  end

  it "falls back to notice styling for unknown types" do
    render_inline(described_class.new(type: :weird, message: "Hm"))

    expect(page).to have_css("div.bg-success-soft", text: "Hm")
  end
end
