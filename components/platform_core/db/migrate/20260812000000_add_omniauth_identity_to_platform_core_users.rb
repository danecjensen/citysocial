class AddOmniauthIdentityToPlatformCoreUsers < ActiveRecord::Migration[7.2]
  def change
    change_table :platform_core_users, bulk: true do |t|
      # OAuth identity (e.g. Google). Nullable: password accounts have neither.
      t.string :provider
      t.string :uid
    end

    add_index :platform_core_users, %i[provider uid], unique: true
  end
end
