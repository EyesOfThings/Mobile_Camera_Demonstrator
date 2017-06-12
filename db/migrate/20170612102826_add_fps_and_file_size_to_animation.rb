class AddFpsAndFileSizeToAnimation < ActiveRecord::Migration[5.0]
  def change
    add_column :animations, :fps, :integer
    add_column :animations, :file_size, :string
  end
end
