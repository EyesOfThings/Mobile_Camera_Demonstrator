class AddIsPublicToAnimations < ActiveRecord::Migration[5.0]
  def change
    add_column :animations, :is_public, :boolean, default: false
  end
end
