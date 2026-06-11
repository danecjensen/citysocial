require "rails_helper"

RSpec.describe PlatformCore::Ui::FormFieldComponent do
  let(:user) { PlatformCore::User.new }
  let(:form) do
    ActionView::Helpers::FormBuilder.new(:user, user, vc_test_controller.view_context, {})
  end

  it "renders a label and input" do
    render_inline(described_class.new(form: form, attribute: :email, type: :email_field, hint: "Private."))

    expect(page).to have_css("label", text: "Email")
    expect(page).to have_css("input[type=email][name='user[email]']")
    expect(page).to have_css("p", text: "Private.")
  end

  it "shows inline errors and danger border" do
    user.errors.add(:email, "is invalid")
    render_inline(described_class.new(form: form, attribute: :email, type: :email_field))

    expect(page).to have_css("p.text-danger", text: "Email is invalid")
    expect(page).to have_css("input.border-danger")
  end

  it "rejects unsupported input types" do
    expect { described_class.new(form: form, attribute: :email, type: :file_field) }
      .to raise_error(ArgumentError)
  end
end
