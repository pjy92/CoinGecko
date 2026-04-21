class CreateUrlVisits < ActiveRecord::Migration[7.2]
  def change
    create_table :url_visits do |t|
      t.references :url, null: false, foreign_key: true
      t.string :ip_address
      t.datetime :visited_at
      t.string :country

      t.timestamps
    end
  end
end
