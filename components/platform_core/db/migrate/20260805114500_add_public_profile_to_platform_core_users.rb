class AddPublicProfileToPlatformCoreUsers < ActiveRecord::Migration[7.2]
  def change
    change_table :platform_core_users, bulk: true do |t|
      t.string :display_name
      t.string :neighborhood
      t.text :bio
    end
  end
end
