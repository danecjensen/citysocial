class CreateMessagingTables < ActiveRecord::Migration[7.2]
  def change
    create_table :messaging_conversations do |t|
      t.bigint :first_participant_id, null: false
      t.bigint :second_participant_id, null: false
      t.datetime :last_message_at

      t.timestamps
    end

    add_index :messaging_conversations, :first_participant_id
    add_index :messaging_conversations, :second_participant_id
    add_index :messaging_conversations,
              %i[first_participant_id second_participant_id],
              unique: true,
              name: "index_messaging_conversations_on_participant_pair"
    add_index :messaging_conversations, :last_message_at

    create_table :messaging_messages do |t|
      t.references :conversation,
                   null: false,
                   foreign_key: { to_table: :messaging_conversations }
      t.bigint :sender_id, null: false
      t.text :body, null: false
      t.datetime :read_at

      t.timestamps
    end

    add_index :messaging_messages, :sender_id
    add_index :messaging_messages, %i[conversation_id created_at]
    add_index :messaging_messages, %i[conversation_id read_at]
  end
end
