class Animations < ActiveRecord::Migration[5.0]
  def change
    create_table :animations do |t|
      t.string :user_email
      t.string :path

      t.timestamps
    end
  end
end
