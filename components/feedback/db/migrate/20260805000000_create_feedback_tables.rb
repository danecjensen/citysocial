class CreateFeedbackTables < ActiveRecord::Migration[7.2]
  def change
    create_table :feedback_submissions do |t|
      t.bigint :author_id, null: false
      t.string :kind, null: false, default: "idea"
      t.string :status, null: false, default: "open"
      t.string :area
      t.string :page_url
      t.string :title, null: false
      t.text :description, null: false
      t.integer :supports_count, null: false, default: 0

      t.timestamps
    end

    add_index :feedback_submissions, :author_id
    add_index :feedback_submissions, :kind
    add_index :feedback_submissions, :status
    add_index :feedback_submissions, :area
    add_index :feedback_submissions, %i[status supports_count]

    create_table :feedback_supports do |t|
      t.references :submission, null: false, foreign_key: { to_table: :feedback_submissions }
      t.bigint :user_id, null: false

      t.timestamps
    end

    add_index :feedback_supports, :user_id
    add_index :feedback_supports, %i[submission_id user_id], unique: true
  end
end
