require "rails_helper"

RSpec.describe Restaurants::Admin::SectionComponent, type: :component do
  # Regression: the add form and every per-row edit form all use
  # `scope: :restaurant`, which without a namespace produced identical DOM ids
  # (`restaurant_photos`, `restaurant_name`, ...) on every form. Duplicate ids
  # make each edit form's "Add photos" label resolve to the *first* matching
  # input -- the add form at the top of the page -- so choosing a file there and
  # saving that row uploaded nothing. Per-form namespaces keep every id unique.
  def render_section
    render_inline(described_class.new(params: {}))
  end

  it "gives each restaurant's photo upload field a unique id" do
    create(:restaurant, :with_photo, name: "Alpha Cafe")
    create(:restaurant, :with_photo, name: "Beta Diner")

    render_section

    file_ids = page.all("input[type=file]", visible: :all).pluck(:id)
    # One add form plus one edit form per restaurant.
    expect(file_ids.size).to eq(3)
    expect(file_ids).to eq(file_ids.uniq)
  end

  it "points every field label at exactly one input" do
    create(:restaurant, :with_photo, name: "Alpha Cafe")
    create(:restaurant, :with_photo, name: "Beta Diner")

    render_section

    label_targets = page.all("label[for]").pluck(:for)
    label_targets.each do |target|
      expect(page.all("##{target}", visible: :all).size).to eq(1)
    end
  end

  it "keeps the submitted parameter names on the shared :restaurant scope" do
    create(:restaurant, :with_photo, name: "Alpha Cafe")

    render_section

    # Namespacing changes ids, not names: the controller still reads
    # restaurant[name] / restaurant[photos][].
    expect(page).to have_css("input[name='restaurant[name]']", visible: :all)
    expect(page).to have_css("input[type=file][name='restaurant[photos][]']", visible: :all)
  end
end
