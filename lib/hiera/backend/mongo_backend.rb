class Hiera
  module Backend
    class Mongo_backend
      def initialize(cache=nil)
    	require 'rubygems' # backward compatibility
        require 'mongo'

        mongo_uri = "mongodb://localhost:27017/hiera"
        Hiera.debug("Hiera Mongodb backend starting")
        config_uri = Backend.datadir('mongo', '')
        mongo_uri = config_uri unless not config_uri.include? "mongodb://"
	mongo_client = Mongo::MongoClient.from_uri(uri = mongo_uri)
        @db = mongo_client.db("hiera")
      end

      def lookup(key, scope, order_override, resolution_type)
        answer = nil

        Hiera.debug("Looking up #{key} in Mongodb backend")

        Backend.datasources(scope, order_override) do |source|
         Hiera.debug("Looking for data source #{source}")

        coll = @db.collection(key)
        data = nil # return nil if there is no results from Mongo
        coll.find.each  { |row|
          data = {} unless not data.nil?
          row.delete_if{|key, value| key == '_id'}
          data.update(row) 
        }
        # Mongo do lookups for us and validate them
        # just pass data object as answer
        new_answer = data
            case resolution_type
            when :array
              raise Exception, "Hiera type mismatch: expected Array and got #{new_answer.class}" unless new_answer.kind_of? Array or new_answer.kind_of? String
              answer ||= []
              answer << new_answer
            when :hash
              raise Exception, "Hiera type mismatch: expected Hash and got #{new_answer.class}" unless new_answer.kind_of? Hash
              answer ||= {}
              answer = Backend.merge_answer(new_answer,answer)
            else
              answer = new_answer
              break
            end
          end

        return answer
      end
    end
end
end
