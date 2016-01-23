require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  

  def where(params)

  	attr_to_find, target_vals = parse_params(params)

    results = DBConnection.execute(<<-SQL, *target_vals)
    	
    	SELECT
    		*
    	FROM
    		#{self.table_name}
    	WHERE
    		#{attr_to_find}
    SQL
    self.parse_all(results)
  end

  private

  def parse_params(params)
  	results = []

  	attr_to_find = []
  	target_vals = []

 		params.each do |attr, val|
 			attr_to_find << "#{attr} = ?"
 			target_vals << val
 		end

 		results << attr_to_find.join(" AND ")
 		results << target_vals

 		results
 	end

end

class SQLObject
  extend Searchable
end
