class CreateNeighborHelpTables < ActiveRecord::Migration[7.2]
  def change
    create_table :neighbor_help_requests do |t|
      t.bigint :requester_id, null: false
      t.bigint :helper_id
      t.string :title, null: false
      t.text :details, null: false
      t.string :category, null: false
      t.string :neighborhood, null: false
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.integer :estimated_minutes, null: false
      t.text :logistics_notes
      t.boolean :no_cash_confirmed, null: false, default: false
      t.string :status, null: false, default: "open"
      t.string :moderation_state, null: false, default: "visible"
      t.timestamps

      t.index %i[moderation_state status ends_at], name: "index_neighbor_help_requests_discovery"
      t.index %i[category ends_at], name: "index_neighbor_help_requests_category"
      t.index :requester_id
      t.index :helper_id
    end

    create_table :neighbor_help_reports do |t|
      t.references :request, null: false, foreign_key: { to_table: :neighbor_help_requests }
      t.bigint :reporter_id, null: false
      t.string :reason, null: false
      t.text :details
      t.string :status, null: false, default: "pending"
      t.timestamps

      t.index %i[request_id reporter_id], unique: true, name: "index_neighbor_help_report_uniqueness"
      t.index %i[status created_at], name: "index_neighbor_help_reports_queue"
      t.index :reporter_id
    end
  end
end
