require 'set'

# @author Katherine Whitlock <toroidalcode@gmail.com>
# @attr_reader primary_key [Symbol] the primary key of the table
# @attr_reader indices [Set<Symbol>] the set of indices for the table
class Chair
  attr_reader :primary_key, :indices

  # Creates a new Table object
  # @param columns [Symbol] columns to insert into the table at initialization
  def initialize(*columns)
    @table = []
    @columns = {}
    @columns_id_counter = 0
    add_columns!(*columns)
    @primary_key = nil
    @indices = Set.new
  end

  # Add a new column to the table.
  # @param column [Symbol] the column name to add
  # @raise [ArgumentError] if the column name is not a symbol
  # @return [Bool] whether or not we successfully added the new column
  def add_column!(column)
    case column
    when Symbol
    else raise ArgumentError, "Column name should be Symbol not #{column.class}"
    end

    if @columns.include? column
      false
    else
      @columns[column] = @columns_id_counter
      @columns_id_counter += 1
      true
    end
  end

  # Add multiple columns to the table
  # @param columns [Symbol] the columns to add
  # @return [Bool] whether or not all of the columns were successfully added
  def add_columns!(*columns)
    result = true
    columns.each { |c| result &&= add_column!(c) }
    result
  end

  # Retrieve the current columns
  # Order is guaranteed to be the order that the columns were inserted in,
  # i.e., left to right
  # @return [Array<Symbol>] the columns in the table
  def columns
    @columns.keys
  end

  # Add a new index to the table
  # @param column [Symbol] the column to create the index on
  # @return [Bool] whether or not we added the index
  def add_index!(column)
    result = false
    get_column_id(column)
    unless instance_variable_defined?("@#{column}_index_map".to_sym)
      instance_variable_set("@#{column}_index_map".to_sym, {})
      result ||= true
    end

    unless @indices.include? column
      @indices = @indices << column
      result ||= true
    end

    build_index column
    result
  end

  # Remove an index from the table
  # @param column [Symbol] the column to remove the index from
  # @return [Bool] whether or not the column was successfully removed
  def remove_index!(column)
    result = false
    if instance_variable_defined?("@#{column}_index_map".to_sym)
      remove_instance_variable("@#{column}_index_map")
      result ||= true
    end
    if @indices.include? column
      @indices = @indices.delete column
      result ||= true
    end
    result
  end

  # Insert a new row of data into the column
  # @param args [Hash, Array] the data to insert
  # @return [Row, nil] the row inserted, or nil if the row was empty
  def insert!(args = {})
    # Fail fast
    if args.empty?
      return nil
    end

    args = case args
             when Hash
               args
             else
               Hash[columns.zip(args.to_a)]
           end

    if has_primary_key?
      if args.include? primary_key
        @pk_map[args[primary_key]] = @table.size
      else # If our table has a primary key, but can't find it in the data
        raise ArgumentError, 'Missing primary key in record to be inserted'
      end
    end
    row = Row.new(self, @table.size, args)
    @table << row
    row
  end

  # Method_missing is used to dispatch to find_by_* and where_*_is
  # @param method_sym [Symbol] the method called
  def method_missing(method_sym, *arguments, &block)
    # the first argument is a Symbol, so you need to_s it if you want to pattern match
    if method_sym.to_s =~ /^find_by_(.*)$/
      find_by($1.to_sym => arguments.first)
    elsif method_sym.to_s =~ /^where_(.*)_is$/
      where($1.to_sym => arguments.first)
    else
      super
    end
  end

  # The number of rows in the table
  # @return [Fixnum] the size
  def size
    @table.size
  end

  alias_method :count, :size

  # Finds a row by searching based on primary key
  # @param pk [Object] The primary key to look up using
  # @return [Row,nil] The row that matches
  def find(pk)
    if has_primary_key?
      idx = @pk_map[pk]
      @table[idx]
    else nil
    end
  end

  # Search for rows based on given data
  # @param args [Hash<Symbol, Object>] the data to search for
  # @return [Array<Row>, nil] the matching rows, can be nil
  def where(args)
    # Try and find a primary key
    if has_primary_key? and args.keys.include? @primary_key
      idx = @pk_map[args[@primary_key]]
      return [@table[idx]]
    end
    indexed_cols = find_valid_indices(args.keys)

    results = @table.to_set

    # First restrict the query as far as we can with indices
    unless indexed_cols.empty?
      indexed_cols.each do |col|
        results = restrict_with_index(col, args[col], results)
      end
    end

    # Then, perform table scans for the rest of the restrictions
    # Removed the indexed columns
    args = args.reject { |col, val| indexed_cols.include? col }
    #slow O(N) find
    args.each_pair do |col, val|
      results = restrict_with_table_scan(col, val, results)
    end
    results.to_a
  end

  # Find a row based on the data given
  # @param args [Hash<Symbol, Object>] the data to search for
  # @return [Row,  nil] the matching row, can be nil
  def find_by(args)
    where(args).first
  end

  # Scan the table to find rows
  # @param args [Hash<Symbol, Object>] the rows to find
  # @return [Array<Row>] the rows found
  def table_scan(args)
    results = @table.to_set
    args.each_pair do |col, value|
      results = restrict_with_table_scan(col, value, results)
    end
    results.to_a
  end

  # Set the primary key of the table.
  # @param column [Symbol] the column to be primary key
  # @return [Symbol, nil] the primary key assigned. can be nil if the column doesn't exist
  def set_primary_key!(column)
    unless @columns.has_key? column
      return nil
    end
    @pk_map = {}
    @primary_key = column
  end

  # Does this table have a primary key?
  # @return [Bool] whether or not there is a primary key
  def has_primary_key?
    not @primary_key.nil?
  end

  # @param [Symbol] column
  # @param [Hash<Object, Object>] map
  # @param [Bool] overwrite
  def merge!(column, map, overwrite: false)

  end

  def all
    @table
  end

  def first
    @table.first
  end

  def last
    @table.last
  end

  protected
  def get_column_id(name)
    id = @columns[name]
    if id.nil?
      raise ArgumentError, "No such column #{name}"
    end
    id
  end

  def find_valid_indices(cols)
    @indices.intersection(cols).to_a
  end

  def restrict_with_index(key, value, initial=@table.to_set)
    idx_map = instance_variable_get("@#{key}_index_map".to_sym)
    unless idx_map.has_key? value
      return Set.new
    end
    row_idxs = idx_map[value]
    if row_idxs.nil?
      return Set.new
    end
    rows = @table.values_at *row_idxs
    initial.intersection rows
  end

  def restrict_with_table_scan(col, value, initial=@table.to_set)
    initial.keep_if { |row| row[col] == value }
  end

  # Scan the table and add all the rows to the index
  # @param column [Symbol] the column to construct the index for
  def build_index(column)
    ivar_name = "@#{column}_index_map".to_sym
    @table.each_with_index do |row, idx|
      val = row[column]
      unless val.nil?
        if instance_variable_get(ivar_name)[val].nil?
          instance_variable_get(ivar_name)[val] = Set.new
        end
        instance_variable_get(ivar_name)[val] =
            instance_variable_get(ivar_name)[val] << idx
      end
    end
    nil
  end
end
