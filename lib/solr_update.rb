require 'rsolr'
require 'geohash'

module SOLR_SEARCH
  GEOHASH_PRECISION = 12
  SOLR_URL = 'http://localhost:8080/solr/'

  def self.solr_update(id, loc_id, name, type_name, longitude, latitude)
    geohash_str = GeoHash.encode latitude, longitude, GEOHASH_PRECISION
    solr = RSolr.connect :url => SOLR_URL
    document = {"id"=> loc_id, "org_id" => id, "name"=> name,
      "type_name" => type_name,
      "longitude" => longitude, "latitude" => latitude,
      "location" => latitude.to_s + ", " + longitude.to_s
    }
    1.upto(GEOHASH_PRECISION) do |i|
      document["geohash_#{i}"] = geohash_str[0..(i-1)]
    end
    response = solr.add [document]
    solr.commit
  end

end
