require_relative '03_associatable'

# Phase IV
module Associatable

  def has_one_through(name, through_name, source_name)
    
    define_method(name) do

    	through_options = self.class.assoc_options[through_name]
    	source_options = through_options.model_class.assoc_options[source_name]

    	owner_id_value = self.send(through_options.foreign_key)
    	
    	results = DBConnection.execute(<<-SQL, owner_id_value)
    		
    		SELECT
    			#{source_options.table_name}.* 
    		FROM
    			#{through_options.table_name} 
    		INNER JOIN
    			#{source_options.table_name} ON 
    				#{source_options.table_name}.id = #{through_options.table_name}.#{source_options.foreign_key}
    		WHERE
    			#{through_options.table_name}.id = ?
    	SQL

    	result = source_options.model_class.parse_all(results).first
    end
  end
end



