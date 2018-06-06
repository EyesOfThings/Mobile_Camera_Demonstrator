class CreateWizards < ActiveRecord::Migration[5.0]
  def change
    create_table :wizards do |t|
      t.string :state
      t.string :email
      t.boolean :is_working

      t.timestamps
    end
  end
end
