require 'spec_helper'

describe Table do
  describe 'initializes' do
    it 'with 0 columns by default' do
      table = Table.new
      expect(table.columns.count).to eq(0)
    end

    it 'with columns given' do
      table = Table.new ['Title', 'Author', 'ISBN']
      expect(table.columns).to eq([:title, :author, :isbn])
    end
  end

  it 'adds a column' do
    table = Table.new
    expect {
      table.add_column(:title)
    }.to change{ table.columns.count }.by(1)
  end
end
