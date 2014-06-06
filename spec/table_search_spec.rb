require 'spec_helper'

describe Table do
  subject(:table) { Table.new :id, :title, :author }

  describe 'finds by' do
    it 'primary key' do
      table.set_primary_key! :title
      table.insert! id: 0, title: 'War and Peace', author: 'Leo Tolstoy'
      expect(table.find('War and Peace').to_a).to eq([0, 'War and Peace', 'Leo Tolstoy'])
    end

    it 'index to use restrict_with_index' do
      table.set_primary_key! :id
      table.add_index! :title
      table.insert! id: 0, title: 'War and Peace', author: 'Leo Tolstoy'
      expect(table).to receive(:restrict_with_index)
      table.find_by(title: 'War and Peace')
    end

    it 'index with method_missing to use restrict_with_index' do
      table.set_primary_key! :id
      table.add_index! :title
      table.insert! id: 0, title: 'War and Peace', author: 'Leo Tolstoy'
      expect(table).to receive(:restrict_with_index)
      table.find_by_title('War and Peace')
    end

    it 'index to return a row' do
      table.set_primary_key! :id
      table.add_index! :title
      table.insert! id: 0, title: 'War and Peace', author: 'Leo Tolstoy'
      row = table.find_by(title: 'War and Peace')
      expect(row.to_a).to eq([0, 'War and Peace', 'Leo Tolstoy'])
    end

    it 'index with method_missing to return a row' do
      table.set_primary_key! :id
      table.add_index! :title
      table.insert! id: 0, title: 'War and Peace', author: 'Leo Tolstoy'
      row = table.find_by_title('War and Peace')
      expect(row.to_a).to eq([0, 'War and Peace', 'Leo Tolstoy'])
    end

    it 'table scan' do
      table.insert! id: 0, title: 'War and Peace', author: 'Leo Tolstoy'
      expect(table.find_by_title('War and Peace').to_a).to eq([0, 'War and Peace', 'Leo Tolstoy'])
    end
  end

  describe 'searches using' do
    it 'primary key' do
      table.set_primary_key! :title
      table.insert! id: 0, title: 'War and Peace', author: 'Leo Tolstoy'
      expect(table.where(title: 'War and Peace').first.to_a).to eq([0, 'War and Peace', 'Leo Tolstoy'])
    end

    it 'dispatch with method_missing' do
      table.set_primary_key! :title
      table.insert! id: 0, title: 'War and Peace', author: 'Leo Tolstoy'
      expect(table.where_title_is('War and Peace').first.to_a).to eq([0, 'War and Peace', 'Leo Tolstoy'])
    end

    it 'table scan' do
      table.insert! id: 0, title: 'War and Peace', author: 'Leo Tolstoy'
      expect(table.where_title_is('War and Peace').first.to_a).to eq([0, 'War and Peace', 'Leo Tolstoy'])
    end
  end
end
