require 'set'
require 'pp'

class Table
  attr_accessor :primary_key, :indices
  # @param [columns] Array<String> An array of columns to start the table with
  def initialize(*columns)
    @table = []
    @columns = {}
    @columns_id_counter = 0
    add_columns!(*columns)
    @primary_key = nil
    @indices = Set.new
  end

  # @param [String] column the column name to add
  def add_column!(column)
    case column
    when Symbol
    else
      raise ArgumentError, "Column name should be Symbol not #{column.class}"
    end

    if @columns.include? column
      false
    else
      @columns[column] = @columns_id_counter
      @columns_id_counter += 1
      true
    end
  end

  def add_columns!(*columns)
    columns.each { |c| add_column! c }
  end

  def columns
    @columns.keys
  end

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


    @table.each_with_index do |row, idx|
      val = row[column]
      unless val.nil?
        if instance_variable_get("@#{column}_index_map".to_sym)[val].nil?
          instance_variable_get("@#{column}_index_map".to_sym)[val] = Set.new
        end
        instance_variable_get("@#{column}_index_map".to_sym)[val] =
            instance_variable_get("@#{column}_index_map".to_sym)[val] << idx
      end
    end
    result
  end

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

  # @param [Hash] options the columns to insert
  def insert!(options = {})
    row = Row.new(self, @table.size)
    options.each_pair do |col, value|
      # If there's a primary_key defined
      if has_primary_key? and columns.include? col and @primary_key == col
        @pk_map[value] = @table.size
      end


      row[col] = value
    end
    unless row.empty?
      @table << row
      row
    end
  end

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

  def size
    @table.size
  end

  alias_method :count, :size

  # @param [Object] pk The primary key to look up using
  # @return [Row] The row that matches
  def find(pk)
    if has_primary_key?
      idx = @pk_map[pk]
      @table[idx]
    else nil
    end
  end

  # @param [Hash] options
  def where(options)
    # Try and find a primary key
    if has_primary_key? and options.keys.include? @primary_key
      idx = @pk_map[options[@primary_key]]
      return [@table[idx]]
    end
    indexed_cols = find_valid_indices(options.keys)

    results = @table.to_set

    # First restrict the query as far as we can with indices
    unless indexed_cols.empty?
      indexed_cols.each do |col|
        results = restrict_with_index(col, options[col], results)
      end
    end

    # Then, perform table scans for the rest of the restrictions
    # Removed the indexed columns
    options = options.reject { |col, val| indexed_cols.include? col }
    #slow O(N) find
    options.each_pair do |col, val|
      results = restrict_with_table_scan(col, val, results)
    end
    results.to_a
  end

  def find_by(options)
    where(options).first
  end

  def table_scan(options)
    results = table
    options.each_pair do |col, value|
      results = restrict(results, col, value)
    end
  end

  def set_primary_key!(column)
    unless @columns.has_key? column
      return nil
    end
    @pk_map = {}
    @primary_key = column
  end

  def has_primary_key?
    not @primary_key.nil?
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

  # @return [Set]
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

  def select(col, table = @table, &block)
    col_id = get_column_id(col)
    table.select do |row|
      block(col)
    end
  end
end
