class AddNameAndProgressToAnimation < ActiveRecord::Migration[5.0]
  def change
    add_column :animations, :progress, :integer
    add_column :animations, :name, :string
  end
end
