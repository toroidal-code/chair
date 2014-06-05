require 'spec_helper'

describe Table do
  subject(:table) { Table.new :id, :title, :author }

  describe 'finds by' do
    it 'primary key' do
      table.set_primary_key :title
      table.insert id: 0, title: 'War and Peace', author: 'Leo Tolstoy'
      expect(table.find('War and Peace').to_a).to eq([0, 'War and Peace', 'Leo Tolstoy'])
    end

    it 'index' do
      table.set_primary_key :id
      table.add_index :title
      table.insert id: 0, title: 'War and Peace', author: 'Leo Tolstoy'
      expect(table).to receive(:restrict_with_index)
      table.find_by(title: 'War and Peace')
    end
  end
end