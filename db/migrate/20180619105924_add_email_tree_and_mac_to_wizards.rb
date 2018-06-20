class AddEmailTreeAndMacToWizards < ActiveRecord::Migration[5.0]
  def change
    add_column :wizards, :email_tree, :string
    add_column :wizards, :mac, :string
  end
end
