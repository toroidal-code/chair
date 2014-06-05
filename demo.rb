table = Table.new [:title, :author]
table.where do |row|
  row[:title]
end
