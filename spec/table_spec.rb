require 'spec_helper'
describe Table do
  describe 'initializes' do
    it 'with 0 columns by default' do
      table = Table.new
      expect(table.columns.count).to eq(0)
    end

    it 'with columns given' do
      table = Table.new ['Title', 'Artist', 'Album']
      expect(table.columns).to eq([:title, :artist, :album])
    end
  end
end
