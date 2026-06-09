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

  describe "managing users" do
    let!(:admin) { create(:user, :admin, handle: "boss") }
    let!(:member) { create(:user, handle: "member") }

    before { login_as(admin) }

    it "promotes a member to admin" do
      patch "/admin/users/#{member.id}", params: { admin: true }
      expect(member.reload.admin?).to be(true)
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
      expect(response).to redirect_to("/admin/users")
    end
  end
end
