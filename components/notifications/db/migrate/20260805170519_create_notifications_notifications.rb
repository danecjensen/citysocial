class CreateNotificationsNotifications < ActiveRecord::Migration[7.2]
  def change
    create_table :notifications_notifications do |t|
      t.bigint :recipient_id, null: false
      t.bigint :actor_id, null: false
      t.string :event_name, null: false
      t.bigint :source_id, null: false
      t.string :message, null: false
      t.string :target_path, null: false
      t.datetime :read_at

      t.timestamps
    end

    add_index :notifications_notifications, %i[recipient_id read_at created_at], name: "index_notifications_inbox"
    add_index :notifications_notifications, %i[recipient_id event_name source_id],
              unique: true, name: "index_notifications_delivery_uniqueness"
  end
end
