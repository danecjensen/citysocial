class AddPasswordToPlatformCoreUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :platform_core_users, :password_digest, :string, null: false, default: ""
    change_column_default :platform_core_users, :password_digest, from: "", to: nil

    change_column_null :platform_core_users, :email, false
    add_index :platform_core_users, :email, unique: true
  end
end
