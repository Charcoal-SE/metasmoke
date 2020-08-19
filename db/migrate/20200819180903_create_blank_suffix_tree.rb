# frozen_string_literal: true

class CreateBlankSuffixTree < ActiveRecord::Migration[5.2]
  def change
    SuffixTree::create! AppConfig['suffix_tree']['path']
  end
end
