class CreateUrls < ActiveRecord::Migration[7.2]
  def change
    create_table :urls do |t|
      t.string :original_url, null: false
      t.string :short_code, null: false
      t.datetime :expires_at
      t.integer :clicks_count, default: 0, null: false

      t.timestamps
    end

    add_index :urls, :short_code, unique: true
    add_index :urls, :expires_at
  end
end
