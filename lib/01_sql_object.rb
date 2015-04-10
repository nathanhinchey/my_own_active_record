require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    query = <<-SQL
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
    # p self.table_name
    DBConnection.execute2(query).first.map(&:to_sym)
  end

  def self.finalize!
    self.columns.each do |column|
      define_method(column) do
        attributes[column]
      end

      define_method("#{column}=") do |value|
        attributes[column] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.name.downcase.pluralize
  end

  def self.all
    query = <<-SQL
    SELECT
      *
    FROM
      #{table_name}
    SQL
    results = DBConnection.execute(query)
    parse_all(results)
  end

  def self.parse_all(results)
    [].tap do |object_array|
      results.each do |result|
        attr_hash = {}
        result.each do |attr_name, attr_value|
          attr_hash[(attr_name.to_sym)] = attr_value
        end
        object_array << self.new(attr_hash)
      end
    end
  end

  def self.find(id)
    query = <<-SQL
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        id = #{id}
    SQL

    result = DBConnection.execute(query)
    parse_all(result).first
  end

  def initialize(params = {})
    all_columns = self.class.columns
    params.each do |attr_name,attr_value|
      unless all_columns.include?(attr_name.to_sym)
        raise "unknown attribute '#{attr_name}'"
      end

      attributes.merge!(params)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map do |column|
      self.send(column)
    end
  end

  def insert
    all_columns = self.class.columns
    query = <<-SQL
      INSERT INTO
        #{self.class.table_name} (#{all_columns.join(", ")})
      VALUES
        (#{(["?"] * all_columns.length).join(', ')})
    SQL

    attributes[:id] = DBConnection.last_insert_row_id

    DBConnection.execute(query, *attribute_values)
  end

  def update
    cols_with_vals = ""

    query <<-SQL
      UPDATE
        #{self.class.table_name}
      SET
        #{cols_with_vals}
      WHERE
        id = #{self.id}
    SQL


  end

  def save
    # ...
  end
end
