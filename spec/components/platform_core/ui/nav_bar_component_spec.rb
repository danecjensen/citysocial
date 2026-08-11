require "rails_helper"

RSpec.describe PlatformCore::Ui::NavBarComponent do
  it "renders top-level links as pills and overflow links inside the hamburger menu" do
    render_inline(described_class.new) do |nav|
      nav.with_link "Feed", "/feed", active: true
      nav.with_menu_link "Communities", "/communities"
    end

    # Primary destination is a top-level pill, not inside the menu.
    expect(page).to have_css("nav > div a.rounded-full[href='/feed']", text: "Feed")

    # Overflow destination lives behind the hamburger disclosure (collapsed, so
    # its links are not visible until opened — match against the full DOM).
    expect(page).to have_css("details[data-controller='menu'] summary[aria-label='More menu']")
    expect(page).to have_css(
      "details[data-controller='menu'] a[href='/communities']", text: "Communities", visible: :all
    )
    expect(page).to have_no_css("details[data-controller='menu'] a[href='/feed']", visible: :all)
  end

  it "marks the active overflow link" do
    render_inline(described_class.new) do |nav|
      nav.with_menu_link "Marketplace", "/marketplace", active: true
    end

    expect(page).to have_css("details a.bg-brand-50[href='/marketplace']", text: "Marketplace", visible: :all)
  end

  it "omits the hamburger entirely when there are no overflow links" do
    render_inline(described_class.new) do |nav|
      nav.with_link "Feed", "/feed"
    end

    expect(page).to have_no_css("details[data-controller='menu']")
  end
end
