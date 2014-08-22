class AddRevenueToLinks < ActiveRecord::Migration
  def change
    add_column :links, :revenue, :integer
  end
end
