class CreateEmails < ActiveRecord::Migration[7.1]
  def change
    create_table :emails do |t|
      t.string :action
      t.string :source
      t.text :destination
      t.string :subject
      t.text :body_text
      t.text :body_html
      t.text :raw_email

      t.timestamps
    end
  end
end
