class CreateMaladies < ActiveRecord::Migration[7.0]
  def change
    create_table :maladies, id: :uuid do |t|
      t.string :maladie_name,          null: false
      t.text :maladie_description
      t.text :synonyms
      t.text :symptoms
      t.text :causes
      t.text :treatments
      t.text :prevention
      t.text :diagnosis
      t.text :references
      t.integer :order, default: 1
      t.boolean  :is_archived, :default => false
      t.boolean :is_cancer, :default => false

      t.timestamps
    end
      # Check if the sequence exists before creating it
      execute <<-SQL
      DO $$
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relkind = 'S' AND relname = 'maladies_order_seq') THEN
          CREATE SEQUENCE maladies_order_seq START 1;
        END IF;
      END
      $$;
    SQL
    # Change the default to use the sequence for 'order'
    change_column_default :maladies, :order, -> { "nextval('maladies_order_seq')" }
  end
end
