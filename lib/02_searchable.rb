require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    vals = []
    cols = []
    params.each do |col, val|
      cols << "#{col} = ?"
      vals << val
    end

    where_query = <<-SQL
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{cols.join(" AND ")}
    SQL
    results = DBConnection.execute(where_query, *vals)
    [].tap do |objects|
      results.each do |result|
        p result
        objects << self.new(result)
        p objects.last
      end
    end
  end
end

class SQLObject
  extend Searchable
end
