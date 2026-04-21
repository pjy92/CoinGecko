class AddTitleToUrls < ActiveRecord::Migration[7.2]
  def change
    add_column :urls, :title, :string
  end
end
