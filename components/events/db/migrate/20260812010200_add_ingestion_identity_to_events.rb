class AddIngestionIdentityToEvents < ActiveRecord::Migration[7.2]
  def up
    add_column :events_events, :external_id, :string

    execute <<~SQL.squish
      UPDATE events_events
      SET source = 'legacy-events-feed'
      WHERE source IS NULL OR BTRIM(source) = ''
    SQL
    execute <<~SQL.squish
      UPDATE events_events
      SET external_id = fingerprint
      WHERE external_id IS NULL
    SQL

    change_column_null :events_events, :source, false
    change_column_null :events_events, :external_id, false
    add_index :events_events, %i[source external_id], unique: true,
                                                    name: "index_events_on_ingestion_identity"
  end

  def down
    remove_index :events_events, name: "index_events_on_ingestion_identity"
    change_column_null :events_events, :source, true
    remove_column :events_events, :external_id
  end
end
