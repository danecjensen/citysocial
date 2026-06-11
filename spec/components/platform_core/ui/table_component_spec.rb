require "rails_helper"

RSpec.describe PlatformCore::Ui::TableComponent do
  it "renders headers and rows with numeric alignment" do
    render_inline(described_class.new(columns: ["Name", { label: "Elo", numeric: true }])) do |table|
      table.with_row do |row|
        row.with_cell { "Franklin" }
        row.with_cell(numeric: true) { "1742" }
      end
    end

    expect(page).to have_css("th", text: "Name")
    expect(page).to have_css("th.text-right", text: "Elo")
    expect(page).to have_css("td", text: "Franklin")
    expect(page).to have_css("td.text-right.font-mono", text: "1742")
  end
end
