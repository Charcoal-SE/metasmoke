# frozen_string_literal: true

class CreateBlankSuffixTree < ActiveRecord::Migration[5.2]
  def change
    SuffixTree::create!(AppConfig['suffix_tree']['str_path'], AppConfig['suffix_tree']['tag_path'],
                        AppConfig['suffix_tree']['child_path'], AppConfig['suffix_tree']['node_path'])
  end
end
