class AddReaderStatusToEmail < ActiveRecord::Migration[7.1]
  def change
    add_column :emails, :reader, :boolean
  end
end
