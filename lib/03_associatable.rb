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
    @class_name.constantize
  end

  def table_name
    model_class::table_name
  end
end

class BelongsToOptions < AssocOptions
  
  def initialize(name, options = {})
    
    default = parse_name(name)
    return_hash = default.merge(options)

    @foreign_key = return_hash[:foreign_key]
    @primary_key = return_hash[:primary_key]
    @class_name = return_hash[:class_name]

  end



  private 

  def parse_name(name)
    name = name.to_s

    results = {}
    results[:foreign_key] = (name + "_id").to_sym
    results[:primary_key] = :id
    results[:class_name] = name.singularize.camelcase

    results
  end
end


class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    
    default = parse_name_class(name, self_class_name)

    return_hash = default.merge(options)

    @foreign_key = return_hash[:foreign_key]
    @primary_key = return_hash[:primary_key]
    @class_name = return_hash[:class_name]

  end



  private

  def parse_name_class(name, self_class_name)

    name = name.to_s
    self_class_name = self_class_name.to_s

    results = {}
    results[:foreign_key] = (self_class_name.downcase + "_id").to_sym
    results[:primary_key] = :id
    results[:class_name] = name.singularize.camelcase

    results

  end

end



module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})

    options = BelongsToOptions.new(name, options)

    define_method(name.to_sym) do
      
      #get value of foreign key
      foreign_key_val = self.send(options.foreign_key)

      #get target model class
      target_class = options.model_class
      instance = target_class.where(id: foreign_key_val).first
    end

    assoc_options[name.to_sym] = options

  end

  def has_many(name, options = {})

    my_class = self

    options = HasManyOptions.new(name, my_class, options)

    define_method(name.to_sym) do
      params = {options.foreign_key => self.id}
      instance = options.model_class.where(params)
    end


  end

  def assoc_options
    @assoc_options ||= {}
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
  end
end

class SQLObject
  extend Associatable
end
