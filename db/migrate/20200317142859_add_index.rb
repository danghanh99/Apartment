class AddIndex < ActiveRecord::Migration[5.1]
  def change
    add_index :orders, [:user_id, :created_at]
  end
end