class CreateRepositoryAccounts < ActiveRecord::Migration[6.1]
  def change
    create_table :repository_accounts do |t|
      t.string :email
      t.string :token
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
