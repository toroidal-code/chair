require 'spec_helper'

describe Chair::Row do
  it 'can get value with []' do
    table = Chair.new :title
    row = Chair::Row.new table,0, {title: 'War and Peace'}
    expect(row[:title]).to eq('War and Peace')
  end

  it 'can set value with []=' do
    table = Chair.new :title
    row = Chair::Row.new table, 0, {title: 'War and Peace'}
    expect{
      row[:title] = 'The Fault in Our Stars'
    }.to change{row.instance_variable_get('@attributes')[:title]}.from('War and Peace').to('The Fault in Our Stars')
  end

  it 'is empty after initialization' do
    table = Chair.new :title
    row = Chair::Row.new(table,0)
    expect(row.empty?).to be(true)
  end

  it 'is not empty when data is present' do
    table = Chair.new :title
    row = Chair::Row.new(table,0, {title: 'Will Grayson, Will Grayson'})
    expect(row.empty?).to be(false)
  end

  it 'can be converted to a hash' do
    table = Chair.new :title, :author
    row = Chair::Row.new table, 0, {title: 'Will Grayson, Will Grayson', author: 'John Green'}
    expect(row.to_hash).to eq({title: 'Will Grayson, Will Grayson',
                               author: 'John Green'})
  end

  it 'can be converted to an array' do
    table = Chair.new :title, :author
    row = Chair::Row.new table, 0, {title: 'Will Grayson, Will Grayson', author: 'John Green'}
    expect(row.to_a).to eq(['Will Grayson, Will Grayson', 'John Green'])
  end


  it 'can compared against an Array with ==' do
    table = Chair.new :title, :author
    row = Chair::Row.new table, 0, {title: 'Will Grayson, Will Grayson', author: 'John Green'}
    expect(row == ['Will Grayson, Will Grayson', 'John Green']).to be(true)
  end

  it 'can compared against another Chair::Row with ==' do
    table = Chair.new :title, :author
    row = Chair::Row.new table, 0, {title: 'Will Grayson, Will Grayson', author: 'John Green'}
    other_row = Chair::Row.new table, 1, {title: 'Will Grayson, Will Grayson', author: 'John Green'}
    expect(row == other_row).to be(true)
  end

  it 'inspect prints values' do
    table = Chair.new :title, :author
    row = Chair::Row.new table, 0, {title: 'Will Grayson, Will Grayson', author: 'John Green'}
  end

  it 'has attribute is true when present' do
    table = Chair.new :title, :author
    row = Chair::Row.new table, 0, {title: 'Will Grayson, Will Grayson'}
    expect(row.has_attribute? :title).to be(true)
  end

  it 'has attribute is false when nil' do
    table = Chair.new :title, :author
    row = Chair::Row.new table, 0, {title: 'Will Grayson, Will Grayson'}
    expect(row.has_attribute? :author).to be(false)
  end

  it 'has attribute is false when empty' do
    table = Chair.new :title, :author
    row = Chair::Row.new table, 0, {title: 'Will Grayson, Will Grayson', author: ''}
    expect(row.has_attribute? :title).to be(true)
  end
end
