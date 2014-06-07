require 'set'

# @author Katherine Whitlock <toroidalcode@gmail.com>
# @attr_reader primary_key [Symbol] the primary key of the table
# @attr_reader indices [Set<Symbol>] the set of indices for the table
class Chair
  attr_reader :primary_key

  # Creates a new Table object
  # @param columns [Symbol] columns to insert into the table at initialization
  def initialize(*columns)
    @table = []
    @columns = {}
    @columns_id_counter = 0
    add_columns!(*columns)
    @primary_key = nil
    @indices = {}
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
  # @return [Symbol] the column name of the index
  def add_index!(column)
    check_column_exists(column)
    if @indices.include?(column) or instance_variable_defined?("@#{column}_index_map".to_sym)
      raise ArgumentError, "Column #{column.inspect} is already an index"
    end

    @indices[column] = "@#{column}_index_map".to_sym
    instance_variable_set(@indices[column], build_index(column))
    column
  end

  # Remove an index from the table
  # @param column [Symbol] the column to remove the index from
  # @return [Symbol] the column that was removed
  def remove_index!(column)
    check_column_exists(column)
    unless @indices.include?(column) or instance_variable_defined?("@#{column}_index_map".to_sym)
      raise ArgumentError, "Column #{column} is not indexed"
    end
    ivar = @indices.delete column
    remove_instance_variable(ivar) unless ivar.nil?
    column
  end

  # Insert a new row of data into the column
  # @param args [Hash, Array] the data to insert
  # @return [Row, nil] the row inserted, or nil if the row was empty
  def insert!(args)
    args = process_incoming_data(args)
    if has_primary_key?
      if args.include? @primary_key
        @pk_map[args[@primary_key]] = @table.size
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

  def indices
    @indices.keys
  end

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
  alias_method :[], :find

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
    unless has_primary_key?
      check_column_exists column
      remove_index!(column) if indices.include? column
      @pk_map = build_pk_map column
      @primary_key = column
    end
  end

  # Does this table have a primary key?
  # @return [Bool] whether or not there is a primary key
  def has_primary_key?
    not @primary_key.nil?
  end

  # Merge the table with a map of primary keys to values. There must be a primary key.
  # @param column [Symbol] the column to insert the values into
  # @param map [Hash<Object, Object>] a mapping of primary_key values to other values
  # @param opts [Bool] :overwrite if a value already exists in the row, overwrite it
  # @param opts [Bool] :create_row if the row doesn't already exist, create it
  def merge!(column, map, opts = {})
    unless has_primary_key?
      raise 'No primary key exists for this table'
    end
    # For each key, value
    map.each_pair do |key, val|
      unless @pk_map.include? key                      # Check if we have the key in our pk_map. if not,
        if opts[:create_row]                            # if we can create rows,
          insert! @primary_key => key, column => val       # create a row
        else raise "No such row with primary key #{key.inspect} exists" # or raise an error
        end
      end
      # if we do, check if the row has a value in the column
      row = @table[@pk_map[key]]
      # if it does, can we overwrite?
      if row.has_attribute?(column) and not opts[:overwrite]
        raise "Value already exists in table for primary key #{key.inspect} and column #{column.inspect}"
      end
      # if so, overwrite
      row[column] = val
    end
    self
  end

  # Retrieve all rows
  # @return [Array<Chair::Row>] all of the rows in the table
  def all
    @table
  end

  # Retrieve the first row in the table
  # @return [Chair::Row] the first row in the table
  def first
    @table.first
  end

  # Retrieve the last row in the table
  # @return [Chair::Row] the last row in the table
  def last
    @table.last
  end

  def inspect
    # Use the table's column list to order our columns
    inspection = []
    inspection << "primary_key: #{@primary_key.inspect}" if has_primary_key?
    inspection << "indices: #{@indices.keys.inspect}" unless @indices.empty?
    inspection << "columns: #{@columns.keys.inspect}" unless @columns.empty?
    inspection = inspection.compact.join(', ')
    unless inspection.empty?
      inspection.insert 0, ' '
    end
    "#<#{self.class}#{inspection}>"
  end

  protected
  def find_valid_indices(cols)
    @indices.keys & cols
  end

  def restrict_with_index(key, value, initial=@table.to_set)
    idx_map = instance_variable_get("@#{key}_index_map".to_sym)
    unless idx_map.has_key? value
      return Set.new
    end
    row_idxs = idx_map[value]
    rows = @table.values_at *row_idxs # *nil is empty call
    initial.intersection rows
  end

  def restrict_with_table_scan(col, value, initial=@table.to_set)
    initial.keep_if { |row| row[col] == value }
  end

  # Scan the table and add all the rows to the index
  # @param column [Symbol] the column to construct the index for
  def build_index(column)
    map = {}
    @table.each_with_index do |row, idx|
      val = row[column]
      unless val.nil?
        map[val] = Set.new if map[val].nil?
        map[val] = map[val] << idx
      end
    end
    map
  end

  def build_pk_map(column)
    map = {}
    @table.each_with_index do |row, idx|
      val = row[column]
      # if the value is nil, we can't use it
      if val.nil? or val.empty?
        raise "Row does not have a value in column #{column.inspect}"
      end

      #if we already have the value in our map, it's not unique and one-to-one
      if map.include?(val)
        raise "Primary key #{val.inspect} is not unique in column #{column.inspect}"
      end

      # otherwise we can assign it
      map[val] = idx
    end
    map
  end

  # @return [Hash] the data in a :column => 'value' format
  def process_incoming_data(args)
    case args
      when Hash
        filtered = args.clone.keep_if{|col,_| @columns.include? col }
        if args != filtered
          invalid = args.clone.delete_if{|col, _| filtered.include? col }.keys.compact.join(', ')
          raise ArgumentError, "No such column(s) #{invalid}"
        end
        filtered
      else  # Because we can guarantee the order of @columns, we use this to zip the array into a hash
        Hash[columns.zip(args.to_a)]
    end
  end

  def check_column_exists(column)
    unless @columns.include?(column)
      raise ArgumentError, "Column #{column.inspect} does not exist in table"
    end
  end
end
