require_relative 'db_connection'
require_relative 'searchable'
require_relative 'associatable'
require_relative 'associatable2'

require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject

  def self.columns
    @columns ||= DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        '#{self.table_name}'
    SQL
    @columns.first.map {|arg| arg.to_sym}
  end

  def self.finalize!

    self.columns.each do |column|
      define_method("#{column}") do
        attributes[column]
      end

      define_method("#{column}=") do |arg|
        attributes[column] = arg
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        '#{self.table_name}'.*
      FROM
        '#{self.table_name}'
    SQL
    self.parse_all(results)
  end

  def self.parse_all(results)
    obj_array = []
    results.each do |hash|
      obj_array << self.new(hash)
    end
    obj_array
  end

  def self.find(id)
    item = DBConnection.execute(<<-SQL, id)
      SELECT
        '#{self.table_name}'.*
      FROM
        '#{self.table_name}'
      WHERE
        '#{self.table_name}'.id = ?
      LIMIT 1
    SQL

    self.parse_all(item).first
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      attr_name = attr_name.to_sym
      raise "unknown attribute '#{attr_name}'" unless self.class.columns.include?(attr_name)
      self.send("#{attr_name}=", value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    attributes.values
  end

  def insert
    
    col_names = self.class.columns.drop(1)
    question_marks = ["?"] * (col_names.length)
    
    col_names = col_names.join(", ")
    question_marks = question_marks.join(", ")

    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update

    col_names = self.class.columns.drop(1).map {|col_name| "#{col_name} = ?"}
    col_names = col_names.join(", ")
    
    attr_values = attribute_values.drop(1)
    attr_values << self.id

    DBConnection.execute(<<-SQL, *attr_values)
      UPDATE
        #{self.class.table_name}
      SET
        #{col_names}
      WHERE
        id = ?
    SQL
  end

  def save
    id.nil? ? insert : update
  end
end
