class AddRunCountToWizards < ActiveRecord::Migration[5.0]
  def change
    add_column :wizards, :run_count, :integer
  end
end
