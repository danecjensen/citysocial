require "rails_helper"

RSpec.describe "Marketplace", type: :request do
  def login_as(user, password: "s3cret-password")
    post "/login", params: { email: user.email, password: password }
  end

  it "browses listings publicly with search and category filters" do
    create(:listing, title: "Vintage Bicycle", category: "for_sale_other")
    create(:listing, title: "Studio Apartment", category: "housing_rent")

    get "/marketplace"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Vintage Bicycle").and include("Studio Apartment")

    get "/marketplace", params: { q: "vintage" }
    expect(response.body).to include("Vintage Bicycle")
    expect(response.body).not_to include("Studio Apartment")

    get "/marketplace", params: { category: "housing_rent" }
    expect(response.body).to include("Studio Apartment")
    expect(response.body).not_to include("Vintage Bicycle")
  end

  it "requires login to post a listing" do
    get "/marketplace/new"
    expect(response).to redirect_to("/login")
  end

  it "creates a listing and increments views on show" do
    login_as(create(:user))

    expect do
      post "/marketplace", params: { listing: { title: "Comfy Sofa", category: "for_sale_furniture", price: "40" } }
    end.to change(Marketplace::Listing, :count).by(1)
    listing = Marketplace::Listing.last
    expect(response).to redirect_to("/marketplace/#{listing.slug}")

    # A non-owner (here, anonymous) viewer bumps the view count.
    delete "/logout"
    expect { get "/marketplace/#{listing.slug}" }.to change { listing.reload.views_count }.by(1)
  end

  it "re-renders the new-listing form with an inline error on the category select when it is blank" do
    login_as(create(:user))

    expect do
      post "/marketplace", params: { listing: { title: "A perfectly nice thing", category: "" } }
    end.not_to change(Marketplace::Listing, :count)

    expect(response).to have_http_status(:unprocessable_content)
    # The category dropdown now composes FormFieldComponent, so the validation
    # error renders inline and the select itself picks up the danger border.
    expect(response.body).to include("Category can&#39;t be blank")
    expect(response.body).to match(/<select\b(?=[^>]*name="listing\[category\]")(?=[^>]*border-danger)[^>]*>/)
  end

  it "lets only the owner mark a listing sold" do
    owner = create(:user)
    listing = create(:listing, author_id: owner.id)

    login_as(create(:user)) # not the owner
    post "/marketplace/#{listing.slug}/mark_sold"
    expect(listing.reload).to be_active

    login_as(owner)
    post "/marketplace/#{listing.slug}/mark_sold"
    expect(listing.reload).to be_sold
  end

  it "blocks the module when disabled, then restores it" do
    create(:listing, title: "Vintage Bicycle")
    PlatformCore::Modules.disable!("marketplace")
    get "/marketplace"
    expect(response).to redirect_to("/")

    PlatformCore::Modules.enable!("marketplace")
    get "/marketplace"
    expect(response).to have_http_status(:ok)
  end
end
