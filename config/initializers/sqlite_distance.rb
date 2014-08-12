config = Rails.configuration.database_configuration
adapters = ["production","development"].map{|x| config[x]["adapter"]}

if adapters.include? "sqlite3"

  require 'active_record/base'
  require 'active_record/connection_adapters/sqlite_adapter'

  module ActiveRecord::ConnectionAdapters
    RADIANS = Math::PI/180.0

    class SQLite3Adapter < SQLiteAdapter
      def initialize(db, logger, config)
        super
        db.create_function('sphere_distance', 5) do |func, lat, lng, qualified_lat_column_name, qualified_lng_column_name, multiplier|
          func.result = Math.acos([1,Math.cos(lat)*Math.cos(lng)*Math.cos(RADIANS*(qualified_lat_column_name))*Math.cos(RADIANS*(qualified_lng_column_name))+
                                           Math.cos(lat)*Math.sin(lng)*Math.cos(RADIANS*(qualified_lat_column_name))*Math.sin(RADIANS*(qualified_lng_column_name))+
                                           Math.sin(lat)*Math.sin(RADIANS*(qualified_lat_column_name))].min)*multiplier
        end
      end
    end
  end
end
