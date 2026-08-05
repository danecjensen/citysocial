require "rails_helper"

RSpec.describe PlatformCore::Ui::AvatarComponent do
  it "renders the resident initial when no avatar is attached" do
    user = build(:user, handle: "dane", display_name: "Dane Jensen")

    render_inline(described_class.new(user: user, size: :lg))

    expect(page).to have_css("span.h-16.w-16", text: "D")
    expect(page).to have_css(%([role=img][aria-label="Dane Jensen's avatar"]))
  end

  it "supports a decorative fallback beside a visible handle" do
    render_inline(described_class.new(user: build(:user), alt: ""))

    expect(page).to have_css("[aria-hidden=true]")
    expect(page).not_to have_css("[role=img]")
  end
end
