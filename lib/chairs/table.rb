require 'active_support/core_ext/string/inflections'

I18n.enforce_available_locales = false

class Table
  # @param [columns] Array<String> An array of columns to start the table with
  def initialize(columns = [])
    @columns = {}
    @columns_id_counter = 0
    add_columns(columns)
  end

  # @param [column] String the column name to add
  def add_column(column)
    case column
    when String
      column = column.parameterize.to_sym
    when Symbol
    else
      raise ArgumentError 'Column name should be a symbol or a string'
    end
    column = column.to_sym
    @columns[column] = @columns_id_counter
    @columns_id_counter += 1
  end

  def add_columns(columns)
    columns.each { |c| add_column c }
  end

  def columns
    @columns.keys
  end

  def insert()
  end

  # Define on self, since it's  a class method
  def self.method_missing(method_sym, *arguments, &block)
    # the first argument is a Symbol, so you need to_s it if you want to pattern match
    if method_sym.to_s =~ /^find_by_(.*)$/
      find($1.to_sym => arguments.first)
    else
      super
    end
  end
end
