class AddAdminToPlatformCoreUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :platform_core_users, :admin, :boolean, null: false, default: false
  end
end
