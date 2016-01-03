class CreateEmailPgpKeys < ActiveRecord::Migration
  def change
    create_table :email_pgp_keys do |t|
      t.integer :owner_id, limit: 4
      t.text :key
      t.boolean :enabled, default: false
      t.text :fingerprint, limit: 40
    end
  end
end
