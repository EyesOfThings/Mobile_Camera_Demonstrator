class AddTimestampToAnimation < ActiveRecord::Migration[5.0]
  def change
    add_column :animations, :unix_time, :integer
  end
end
