# frozen_string_literal: true

class CreateCompanyDocuments < ActiveRecord::Migration[7.0]
  def change
    create_table :company_documents, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :name, null: false
      t.text :description
      t.string :document_type, default: 'other'
      t.string :category
      t.bigint :file_size
      t.string :file_type
      t.references :company, null: false, foreign_key: true, type: :uuid
      t.references :uploaded_by, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.boolean :is_public, default: false
      t.datetime :expires_at
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :company_documents, :document_type
    add_index :company_documents, :category
    add_index :company_documents, :is_public
  end
end
