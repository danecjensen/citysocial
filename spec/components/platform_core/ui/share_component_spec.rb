require "rails_helper"

RSpec.describe PlatformCore::Ui::ShareComponent do
  it "renders a permanent copy fallback and an initially hidden native share action" do
    render_inline(described_class.new(title: "Austin & neighbors", url: "https://example.test/events/e/42?from=city"))

    expect(page).to have_css(
      "[data-controller='share'][data-share-title-value='Austin & neighbors']" \
      "[data-share-url-value='https://example.test/events/e/42?from=city']"
    )
    expect(page).to have_css("button[type='button'][data-action='share#copy']", text: "Copy link")
    expect(page).to have_css("[data-share-target='native'][hidden] button[data-action='share#native']", text: "Share")
    expect(page).to have_css("[data-share-target='status'][role='status'][aria-live='polite']")
  end
end
