# frozen_string_literal: true

class CreateBlankSuffixTree < ActiveRecord::Migration[5.2]
  def change
    if AppConfig['suffix_tree']['inplace_create']
      SuffixTree::placement_create! AppConfig['suffix_tree']['path']
    else
      SuffixTree::create! AppConfig['suffix_tree']['path']
    end
  end
end
