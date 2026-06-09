class CreatePlatformCoreUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :platform_core_users do |t|
      t.string :handle, null: false
      t.string :email
      t.timestamps
    end
    add_index :platform_core_users, :handle, unique: true
  end
end
