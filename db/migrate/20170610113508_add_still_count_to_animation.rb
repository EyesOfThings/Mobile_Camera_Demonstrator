class AddStillCountToAnimation < ActiveRecord::Migration[5.0]
  def change
    add_column :animations, :image_count, :string
  end
end
