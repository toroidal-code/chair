require 'spec_helper'

describe Chair do
  describe 'initializes' do
    it 'with no columns' do
      table = Chair.new
      expect(table.columns.count).to eq(0)
    end

    it 'with no rows' do
      table = Chair.new
      expect(table.size).to eq(0)
    end

    it 'with no primary key' do
      table = Chair.new
      expect(table.has_primary_key?).to eq(false)
    end

    it 'with no indices' do
      table = Chair.new
      expect(table.indices.size).to eq(0)
    end

    it 'with specified columns' do
      table = Chair.new :title, :author, :isbn
      expect(table.columns).to eq([:title, :author, :isbn])
    end
  end

  it 'adds a column' do
    table = Chair.new
    expect {
      table.add_column!(:title)
    }.to change{ table.columns.count }.by(1)
  end

  it 'raises an ArgumentError if the name is not a symbol' do
    table = Chair.new
    expect{
      table.add_column!('Title')
    }.to raise_error(ArgumentError)
  end

  it "doesn't add column with the same name" do
    table = Chair.new :title
    expect {
      table.add_column!(:title)
    }.to_not change{ table.columns.count }
  end

  it 'adds multiple columns' do
    table = Chair.new
    expect {
      table.add_columns! :title, :author
    }.to change {table.columns.count}.by(2)
  end

  describe 'inserts a row' do
    it 'from a hash' do
      table = Chair.new :title
      expect {
        table.insert!({title: 'Gone with the Wind'})
      }.to change { table.size }.by(1)
    end

    it 'from an array' do
      table = Chair.new :title
      expect {
        table.insert!(['Gone with the Wind'])
      }.to change { table.size }.by(1)
    end
  end

  describe 'setting primary key' do
    it 'with valid params is successful' do
      table = Chair.new :title
      expect {
        table.set_primary_key! :title
      }.to change {table.primary_key}.from(nil).to(:title)
    end

    describe 'fails to build index' do
      it 'when duplicate fields exist' do
        table = Chair.new :title
        table.insert! title: 'Looking for Alaska'
        table.insert! title: 'Looking for Alaska'
        expect {
          table.set_primary_key! :title
        }.to raise_error RuntimeError, 'Primary key "Looking for Alaska" is not unique in column :title'
      end

      it 'when fields are nil' do
        table = Chair.new :title
        table.insert! title: 'Looking for Alaska'
        table.insert! title: nil
        expect {
          table.set_primary_key! :title
        }.to raise_error RuntimeError, 'Row does not have a value in column :title'
      end

      it 'when fields are empty' do
        table = Chair.new :title
        table.insert! title: 'Looking for Alaska'
        table.insert! title: ''
        expect {
          table.set_primary_key! :title
        }.to raise_error RuntimeError, 'Row does not have a value in column :title'
      end

    end
  end

  it "doesn't set the primary key if it's not a valid column" do
    table = Chair.new
    expect{
      table.set_primary_key! :title
    }.not_to change{table.primary_key}.from(nil)
  end

  it "doesn't set the primary key if there's already a primary key" do
    table = Chair.new
    expect{
      table.set_primary_key! :title
    }.not_to change{table.primary_key}.from(nil)
  end

  describe 'add index' do
    it 'succeeds with valid params' do
      table = Chair.new :title
      expect {
        table.add_index! :title
      }.to change {table.indices.size}.by(1)
    end

    it "should raise ArgumentError when a column doesn't exist" do
      table = Chair.new
      expect{table.add_index! :title}.to raise_error(ArgumentError)
    end

    it 'should raise ArgumentError when a column is already indexed' do
      table = Chair.new :title
      table.add_index! :title
      expect{table.add_index! :title}.to raise_error(ArgumentError)
    end

  end

  describe 'remove index' do
    it 'succeeds with valid params' do
      table = Chair.new :title
      table.add_index! :title
      expect {
        table.remove_index! :title
      }.to change {table.indices.size}.by(-1)
    end

    it "should raise ArgumentError when a column doesn't exist" do
      table = Chair.new
      expect{table.remove_index! :title}.to raise_error(ArgumentError)
    end

    it 'should raise ArgumentError when a column is not indexed' do
      table = Chair.new :title
      expect{table.remove_index! :title}.to raise_error(ArgumentError)
    end
  end


  it 'builds an index of existing data' do
    table = Chair.new :title
    table.insert! title: 'The Fault in Our Stars'
    table.add_index! :title
    expect(
      table.instance_variable_get("@title_index_map").has_key? 'The Fault in Our Stars'
    ).to eq(true)
  end

  it 'adds data to the index' do
    table = Chair.new :title
    table.add_index! :title
    expect {
      table.insert! title: 'The Fault in Our Stars'
    }.to change{table.instance_variable_get("@title_index_map").size}.by(1)
  end

  it 'data must have primary key if primary key is defined' do
    table = Chair.new :title, :author
    table.set_primary_key! :title
    expect {
      table.insert! author: 'John Green'
    }.to raise_error ArgumentError
  end

  it 'cannot insert a row if no such column exists' do
    table = Chair.new :title
    expect {
      table.insert! title:'The Fault in Our Stars', author: 'John'
    }.to raise_error ArgumentError
  end

  describe 'merge' do
    it 'data into the table' do
      table = Chair.new :num, :string
      table.set_primary_key! :num
      table.insert! num: 123
      table.insert! num: 456
      table.merge!(:string, {123 => '123',
                             456 => '456'})
      expect(table.find(123)[:string]).to eq('123')
      expect(table.find(456)[:string]).to eq('456')
    end

    it 'should raise RuntimeError when no primary key' do
      table = Chair.new :num, :string
      expect {
        table.merge!(:string, {123 => '123',
                               456 => '456'})
      }.to raise_error RuntimeError, 'No primary key exists for this table'
    end

    it 'should raise RuntimeError when no such key exists' do
      table = Chair.new :num, :string
      table.set_primary_key! :num
      expect {
        table.merge!(:string, {123 => '123',
                               456 => '456'})
      }.to raise_error RuntimeError, 'No such row with primary key 123 exists'
    end

    it 'should raise RuntimeError instead of overwrite data by default' do
      table = Chair.new :num, :string
      table.set_primary_key! :num
      table.insert! num: 123, string: '123'
      table.insert! num: 456
      expect {
        table.merge!(:string, {123 => '123',
                               456 => '456'})
      }.to raise_error RuntimeError, 'Value already exists in table for primary key 123 and column :string'
    end
  end

end
