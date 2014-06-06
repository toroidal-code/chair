require 'spec_helper'

describe Table do
  describe 'initializes' do
    it 'with 0 columns by default' do
      table = Table.new
      expect(table.columns.count).to eq(0)
    end

    it 'with 0 rows by default' do
      table = Table.new
      expect(table.size).to eq(0)
    end

    it 'with columns given' do
      table = Table.new :title, :author, :isbn
      expect(table.columns).to eq([:title, :author, :isbn])
    end

    it 'with no primary key' do
      table = Table.new
      expect(table.has_primary_key?).to eq(false)
    end

    it 'with no indices' do
      table = Table.new
      expect(table.indices.size).to eq(0)
    end
  end

  it 'adds a column' do
    table = Table.new
    expect {
      table.add_column!(:title)
    }.to change{ table.columns.count }.by(1)
  end

  it 'raises an ArgumentError if the name is not a symbol' do
    table = Table.new
    expect{
      table.add_column!('Title')
    }.to raise_error(ArgumentError)
  end

  it 'doesn\'t add column with the same name' do
    table = Table.new :title
    expect {
      table.add_column!(:title)
    }.to_not change{ table.columns.count }
  end

  it 'adds multiple columns' do
    table = Table.new
    expect {
      table.add_columns! :title, :author
    }.to change {table.columns.count}.by(2)
  end

  it 'inserts a row' do
    table = Table.new :title
    expect {
      table.insert!({title: "Gone with the Wind"})
    }.to change { table.size }.by(1)
  end

  it 'sets the primary key' do
    table = Table.new :title
    expect {
      table.set_primary_key! :title
    }.to change {table.primary_key}.from(nil).to(:title)
  end

  it "doesn't set the primary key if it's not a column" do
    table = Table.new
    expect{
      table.set_primary_key! :title
    }.not_to change{table.primary_key}.from(nil)
  end

  it 'adds an index' do
    table = Table.new :title
    expect {
      table.add_index! :title
    }.to change {table.indices.size}.by(1)
  end

  it 'deletes an index' do
    table = Table.new :title
    table.add_index! :title
    expect {
      table.remove_index! :title
    }.to change {table.indices.size}.by(-1)
  end
end
