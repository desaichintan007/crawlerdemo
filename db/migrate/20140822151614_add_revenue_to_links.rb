class AddRevenueToLinks < ActiveRecord::Migration
  def change
    add_column :links, :revenue, :string
  end
end
