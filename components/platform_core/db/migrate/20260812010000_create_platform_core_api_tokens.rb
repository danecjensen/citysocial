class CreatePlatformCoreApiTokens < ActiveRecord::Migration[7.2]
  def change
    create_table :platform_core_api_tokens do |t|
      t.bigint :user_id, null: false
      t.string :source, null: false
      t.string :token_digest, null: false
      t.datetime :last_used_at
      t.datetime :revoked_at
      t.timestamps
    end

    add_index :platform_core_api_tokens, :token_digest, unique: true
    add_index :platform_core_api_tokens, :source
    add_index :platform_core_api_tokens, :user_id
  end
end
