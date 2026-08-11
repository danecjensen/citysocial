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

  it "routes attached avatars through the host application's Active Storage mount" do
    user = create(:user, handle: "dane")
    user.avatar.attach(io: StringIO.new("image"), filename: "avatar.png", content_type: "image/png")

    render_inline(described_class.new(user: user))

    expect(page).to have_css('img[src^="/rails/active_storage/blobs/redirect/"]')
    expect(page).not_to have_css('img[src^="/platform_core/rails/active_storage/"]')
  end

  it "falls back safely when a rejected upload has an unpersisted blob" do
    user = build(:user, handle: "dane")
    user.avatar.attach(io: StringIO.new("not an image"), filename: "avatar.gif", content_type: "image/gif")

    render_inline(described_class.new(user: user))

    expect(page).to have_css("span", text: "D")
  end
end
