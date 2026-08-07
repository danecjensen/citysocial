class AddContextToMessagingConversations < ActiveRecord::Migration[7.2]
  def change
    add_column :messaging_conversations, :context_path, :string, limit: 500
    add_column :messaging_conversations, :context_label, :string, limit: 120
  end
end
