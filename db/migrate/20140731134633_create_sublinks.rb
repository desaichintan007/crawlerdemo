class CreateSublinks < ActiveRecord::Migration
  def change
    create_table :sublinks do |t|
      t.integer :link_id
      t.text :url
      t.text :content

      t.timestamps
    end
  end
end
