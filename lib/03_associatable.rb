require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @foreign_key = options[:foreign_key] ||= (name.to_s + "_id").to_sym
    @primary_key = options[:primary_key] ||= (:id)
    @class_name = options[:class_name] ||= name.to_s.camelcase
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @foreign_key = options[:foreign_key] ||= (self_class_name.downcase + "_id").to_sym
    @primary_key = options[:primary_key] ||= (:id)
    @class_name = options[:class_name] ||= name.to_s.camelcase.singularize
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)

    define_method(name) do
      owner_id = self.send(options.foreign_key)
      owner_class = options.model_class

      @owner ||= owner_class.where(id: owner_id).first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.name, options)

    define_method(name) do
      child_class = options.model_class
      foreign_key = options.foreign_key

      @child ||= child_class.where(foreign_key => self.id)
    end
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
  end
end

class SQLObject
  extend Associatable
end
