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

  it "renders a styled file field with accepted content types" do
    render_inline(described_class.new(form: form, attribute: :avatar, type: :file_field,
                                      accept: "image/png,image/jpeg"))

    expect(page).to have_css("input[type=file][name='user[avatar]'][accept='image/png,image/jpeg']")
  end

  it "rejects unsupported input types" do
    expect { described_class.new(form: form, attribute: :email, type: :date_field) }
      .to raise_error(ArgumentError)
  end

  it "renders a select with its collection and a blank prompt" do
    render_inline(described_class.new(form: form, attribute: :email, type: :select,
                                      label: "Provider", include_blank: "Choose one",
                                      collection: [%w[Gmail gmail], %w[Proton proton]]))

    expect(page).to have_css("label", text: "Provider")
    expect(page).to have_css("select[name='user[email]']")
    expect(page).to have_css("select option[value='gmail']", text: "Gmail")
    expect(page).to have_css("select option", text: "Choose one")
  end

  it "preselects the record's current value when no explicit selection is given" do
    user.handle = "gmail"
    render_inline(described_class.new(form: form, attribute: :handle, type: :select,
                                      collection: [%w[Gmail gmail], %w[Proton proton]]))

    expect(page).to have_css("select option[selected][value='gmail']", text: "Gmail")
    expect(page).not_to have_css("select option[selected][value='proton']")
  end

  it "lets an explicit selection override the record's current value" do
    user.handle = "gmail"
    render_inline(described_class.new(form: form, attribute: :handle, type: :select,
                                      selected: "proton",
                                      collection: [%w[Gmail gmail], %w[Proton proton]]))

    expect(page).to have_css("select option[selected][value='proton']", text: "Proton")
    expect(page).not_to have_css("select option[selected][value='gmail']")
  end

  it "shows inline errors and danger border on a select" do
    user.errors.add(:email, "must be chosen")
    render_inline(described_class.new(form: form, attribute: :email, type: :select,
                                      collection: [%w[Gmail gmail]]))

    expect(page).to have_css("p.text-danger", text: "Email must be chosen")
    expect(page).to have_css("select.border-danger")
  end

  it "requires a collection for a select" do
    expect { described_class.new(form: form, attribute: :email, type: :select) }
      .to raise_error(ArgumentError)
  end
end
