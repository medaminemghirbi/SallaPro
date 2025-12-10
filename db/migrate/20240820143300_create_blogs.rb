class CreateBlogs < ActiveRecord::Migration[7.0]
  def change
    create_table :blogs, id: :uuid do |t|
      t.string :title
      t.text :content
      t.uuid :doctor_id, null: false
      t.uuid :maladie_id, null: false

      t.boolean :is_archived, default: false
      t.boolean :is_verified, default: false
      t.integer :order, default: 1
      t.timestamps
    end

    # Check if the sequence exists before creating it
    execute <<-SQL
      DO $$
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relkind = 'S' AND relname = 'blogs_order_seq') THEN
          CREATE SEQUENCE blogs_order_seq START 1;
        END IF;
      END
      $$;
    SQL

    # Change the default to use the sequence for 'order'
    change_column_default :blogs, :order, -> { "nextval('blogs_order_seq')" }
  end
end
