class Row

  def initialize(table)
    @table = table
    @row = []
  end

  def [](col)
    idx = @table.send(:get_column_id, col)
    @row[idx]
  end

  def []=(col, value)
    idx = @table.send(:get_column_id, col)
    @row[idx] = value
  end

  def empty?
    @row.empty?
  end

  def to_hash
    map = {}
    @table.columns.each do |col|
      idx = @table.send(:get_column_id, col)
      map[col] = row[idx]
    end
    map
  end

  def to_a
    @row
  end

  def eql?(other)
    @row.eql?(other.instance_variable_get("@row"))
  end

end