class CreateVisits < ActiveRecord::Migration[7.2]
  def change
    create_table :visits do |t|
      t.references :url, null: false, foreign_key: true
      t.string :ip
      t.string :user_agent

      t.timestamps
    end
  end
end
