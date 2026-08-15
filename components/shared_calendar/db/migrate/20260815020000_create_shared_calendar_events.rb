class CreateSharedCalendarEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :shared_calendar_events do |t|
      t.bigint :author_id, null: false
      t.string :title, null: false
      t.text :description
      t.string :category, null: false
      t.datetime :starts_at, null: false
      t.datetime :ends_at
      t.string :venue_name
      t.string :location

      t.timestamps
    end

    add_index :shared_calendar_events, :author_id
    add_index :shared_calendar_events, :category
    add_index :shared_calendar_events, :starts_at
  end
end
