require "rails_helper"

RSpec.describe "Admin area", type: :request do
  def login_as(user, password: "s3cret-password")
    post "/login", params: { email: user.email, password: password }
  end

  describe "authorization" do
    it "redirects anonymous users to login" do
      get "/admin"
      expect(response).to redirect_to("/login")
    end

    it "redirects logged-in non-admins away from the admin area" do
      login_as(create(:user))
      get "/admin"
      expect(response).to redirect_to("/")
    end

    it "lets admins in" do
      login_as(create(:user, :admin))
      get "/admin"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "the single-page dashboard" do
    before { login_as(create(:user, :admin)) }

    it "renders every registered section on one page" do
      create(:restaurant, name: "Franklin Barbecue")
      create(:feedback_submission, title: "Add a dark mode toggle")

      get "/admin"

      expect(response.body).to include('id="section-users"')
      expect(response.body).to include('id="section-modules"')
      expect(response.body).to include('id="section-restaurants"')
      expect(response.body).to include('id="section-feedback"')
      expect(response.body).to include("Franklin Barbecue")
      expect(response.body).to include("Add a dark mode toggle")
    end

    it "drops a disabled module's section from the page" do
      create(:restaurant, name: "Franklin Barbecue")
      PlatformCore::Modules.disable!("restaurants")

      get "/admin"

      expect(response.body).to include('id="section-users"')
      expect(response.body).not_to include('id="section-restaurants"')
      expect(response.body).not_to include("Franklin Barbecue")
    end

    it "sends the module-specific admin paths back to their section" do
      get "/restaurants/admin/restaurants"
      expect(response).to redirect_to("/admin#section-restaurants")

      get "/feedback/admin"
      expect(response).to redirect_to("/admin#section-feedback")
    end
  end

  describe "managing users" do
    let!(:admin) { create(:user, :admin, handle: "boss") }
    let!(:member) { create(:user, handle: "member") }

    before { login_as(admin) }

    it "promotes a member to admin" do
      patch "/admin/users/#{member.id}", params: { admin: true }
      expect(member.reload.admin?).to be(true)
      expect(response).to redirect_to("/admin#section-users")
    end

    it "revokes admin from a user" do
      other = create(:user, :admin)
      patch "/admin/users/#{other.id}", params: { admin: false }
      expect(other.reload.admin?).to be(false)
    end

    it "deletes a user" do
      expect do
        delete "/admin/users/#{member.id}"
      end.to change(PlatformCore::User, :count).by(-1)
    end

    it "refuses to delete the current admin's own account" do
      expect do
        delete "/admin/users/#{admin.id}"
      end.not_to change(PlatformCore::User, :count)
      expect(response).to redirect_to("/admin#section-users")
    end
  end

  describe "toggling modules" do
    before { login_as(create(:user, :admin)) }

    it "disables a module and sends the admin back to the modules section" do
      patch "/admin/modules/marketplace", params: { enabled: false }

      expect(PlatformCore::Modules.enabled?("marketplace")).to be(false)
      expect(response).to redirect_to("/admin#section-modules")
    end
  end
end
