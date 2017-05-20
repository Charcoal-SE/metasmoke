class CreatePostsAndReasons < ActiveRecord::Migration[4.2]
  def change
    create_table :posts do |t|
      t.string :title
      t.text :body
      t.string :link
      t.timestamp :post_creation_date
    end

    create_table :reasons do |t|
      t.string :reason_name
    end

    create_table :posts_reasons, id: false do |t|
      t.belongs_to :reason, index: true
      t.belongs_to :post, index: true
    end
  end
end
