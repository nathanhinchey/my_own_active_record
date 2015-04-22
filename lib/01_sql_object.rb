require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject

  def self.columns
    columns_query = <<-SQL
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
    # p self.table_name
    DBConnection.execute2(columns_query).first.map(&:to_sym)
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
    @table_name || self.name.downcase.pluralize
  end

  def self.all
    all_query = <<-SQL
    SELECT
      *
    FROM
      #{table_name}
    SQL
    results = DBConnection.execute(all_query)
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
    find_query = <<-SQL
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        id = ?
    SQL

    result = DBConnection.execute(find_query, id)
    parse_all(result).first
  end

  def initialize(params = {})
    params = turn_string_keys_to_sym(params)
    all_columns = self.class.columns
    params.each do |attr_name,attr_value|
      unless all_columns.include?(attr_name.to_sym)
        raise "unknown attribute '#{attr_name}'"
      end

      attributes.merge!(params)
    end
  end

  def turn_string_keys_to_sym(hash_with_string_keys)
    hash_with_sym_keys = {}
    hash_with_string_keys.each do |key, value|
      hash_with_sym_keys[key.to_sym] = value
    end

    hash_with_sym_keys
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
    insert_query = <<-SQL
      INSERT INTO
        #{self.class.table_name} (#{all_columns.join(", ")})
      VALUES
        (#{(["?"] * all_columns.length).join(', ')})
    SQL

    attributes[:id] = DBConnection.last_insert_row_id

    DBConnection.execute(insert_query, *attribute_values)
  end

  def update
    all_columns = self.class.columns
    cols_with_question_marks = all_columns.join(' = ?,') << " = ?"

    update_query = <<-SQL
      UPDATE
        #{self.class.table_name}
      SET
        #{cols_with_question_marks}
      WHERE
        id = ?
    SQL

    DBConnection.execute(update_query, *attribute_values, self.id)
  end

  def save
    if self.id == nil
      insert
    else
      update
    end
  end
end
