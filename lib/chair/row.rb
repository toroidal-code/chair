class Row
  include Comparable

  # Create a new cell
  # @param table [Table] the table holding this row
  # @param id [Fixnum] the array index of this row in the interal 2D array
  def initialize(table, id, data = [])
    @row_id = id
    @table = table
    @row = data
  end

  # Get a cell based on the column name
  # @return [Object, nil] the value in the cell, can be nil
  def [](col)
    idx = @table.send(:get_column_id, col)
    @row[idx]
  end

  # Assign a new value to one of the cells in the row
  # @param col [Symbol] the column name to add to
  # @param value [Object] the value to assign
  # @return [Object] the assigned value
  def []=(col, value)
    idx = @table.send(:get_column_id, col)
    if @table.indices.include? col
      if @table.instance_variable_get("@#{col}_index_map".to_sym)[value].nil?
        @table.instance_variable_get("@#{col}_index_map".to_sym)[value] = Set.new
      end
      @table.instance_variable_get("@#{col}_index_map")[value] =
          @table.instance_variable_get("@#{col}_index_map")[value] << @row_id
    end
    @row[idx] = value
  end

  def empty?
    @row.empty?
  end

  # Create a hash of the data based on the columns
  # @return [Hash<Symbol, Object>] the data in the row
  def to_hash
    map = {}
    @table.columns.each do |col|
      idx = @table.send(:get_column_id, col)
      map[col] = @row[idx]
    end
    map
  end

  # Convert the row data to an array
  # @return [Array<Object>] the data in the row
  def to_a
    @row
  end

  # Compare Row instances based on internal representation
  # @param other [Object] the object to compare to
  # @return [Bool] whether or not the objects are the same
  def ==(other)
    case other
      when Row
        @row == other.instance_variable_get("@row")
      when Array
        @row == other
      else false
    end
  end

  # Compare rows within a table
  # @param other [Object] the object to compare to
  def <=>(other)
    # only be comparable if we're in the same table
    if @table.equal?(other.instance_variable_get(@table))
      other_id = other.instance_variable_get("@id")
      @id <=> other_id
    else
      nil
    end
  end
end
