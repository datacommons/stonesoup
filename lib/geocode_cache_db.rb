module GEOCODE_CACHE_DB
  class Geocode_Cache_Entry < ActiveRecord::Base
    establish_connection :geocode_cache_db
  end
end
