class Chair::Row
  include Comparable

  # Create a new cell
  # @param table [Table] the table holding this row
  # @param id [Fixnum] the array index of this row in the internal 2D array
  def initialize(table, id, data = {})
    @row_id = id
    @table = table
    @attributes = data
    @attributes.clone.
        keep_if{ |col, _| @table.indices.include? col }.
        each_pair{ |col, val| add_to_index(col, val) }
  end

  # Get a cell based on the column name
  # @return [Object, nil] the value in the cell, can be nil
  def [](column)
    @attributes[column]
  end

  # Assign a new value to one of the cells in the row
  # @param column [Symbol] the column name to add to
  # @param value [Object] the value to assign
  # @return [Object] the assigned value
  def []=(column, value)
    if @table.indices.include? column
      add_to_index(column, value)
    end
    @attributes[column] = value
  end

  def empty?
    @attributes.empty?
  end

  # Create a hash of the data based on the columns
  # @return [Hash<Symbol, Object>] the data in the row
  def to_hash
    @attributes
  end

  # Convert the row data to an array
  # @return [Array<Object>] the data in the row
  def to_a
    @table.columns.map { |col| @attributes[col] }
  end

  # Compare Row instances based on internal representation
  # @param other [Object] the object to compare to
  # @return [Bool] whether or not the objects are the same
  def ==(other)
    case other
      when Chair::Row
        @attributes == other.instance_variable_get('@attributes')
      when Array
        @attributes.values == other
      else false
    end
  end

  # Compare rows within a table
  # @param other [Object] the object to compare to
  def <=>(other)
    # only be comparable if we're in the same table
    if @table.equal?(other.instance_variable_get(@table))
      other_id = other.instance_variable_get('@id')
      @id <=> other_id
    else
      nil
    end
  end

  # Returns the contents of the record as a nicely formatted string.
  def inspect
    pairs = []
    # Use the table's column list to order our columns
    @table.columns.each { |name| pairs << "#{name}: #{@attributes[name].inspect}"}
    inspection = pairs.compact.join(', ')
    "#<#{self.class} #{inspection}>"
  end

  # Looks to see if we have a attribute
  # @param name [Symbol] the column to look at
  # @return [Bool] whether or not the value is empty
  def has_attribute?(name)
    val = @attributes[name]
    val.nil? ? false : (not val.empty?)
  end

  def method_missing(method_sym, *arguments, &block)
    # the first argument is a Symbol, so you need to_s it if you want to pattern match
    if method_sym.to_s =~ /^has_(.*)\?$/
      has_attribute?($1.to_sym)
    elsif @attributes.has_key? method_sym
      @attributes[method_sym]
    else
      super
    end
  end

  protected
  def add_to_index(column, value)
    if @table.instance_variable_get("@#{column}_index_map".to_sym)[value].nil?
      @table.instance_variable_get("@#{column}_index_map".to_sym)[value] = Set.new
    end
    @table.instance_variable_get("@#{column}_index_map")[value] =
        @table.instance_variable_get("@#{column}_index_map")[value] << @row_id
  end
end
