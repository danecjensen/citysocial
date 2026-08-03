class CreatePlatformCoreModules < ActiveRecord::Migration[7.2]
  def change
    create_table :platform_core_modules do |t|
      t.string :key, null: false
      t.boolean :enabled, null: false, default: true

      t.timestamps
    end

    add_index :platform_core_modules, :key, unique: true
  end
end
