class AddCurationDetailsToEvents < ActiveRecord::Migration[7.2]
  def change
    add_column :events_events, :why, :text
    add_column :events_events, :ticket_urgency, :string
    add_column :events_events, :age_limit, :string
  end
end
