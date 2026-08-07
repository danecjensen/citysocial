class AddArchivingToMessagingConversations < ActiveRecord::Migration[7.2]
  def change
    add_column :messaging_conversations, :first_participant_archived_at, :datetime
    add_column :messaging_conversations, :second_participant_archived_at, :datetime

    add_index :messaging_conversations,
              %i[first_participant_id first_participant_archived_at],
              name: "index_messaging_conversations_on_first_archive"
    add_index :messaging_conversations,
              %i[second_participant_id second_participant_archived_at],
              name: "index_messaging_conversations_on_second_archive"
  end
end
