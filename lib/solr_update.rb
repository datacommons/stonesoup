require 'rsolr'
require 'geohash'

module SOLR_SEARCH
  GEOHASH_PRECISION = 12
  SOLR_URL = 'http://localhost:8080/solr/'

  def self.create_solr_connection()
    solr = RSolr.connect :url => SOLR_URL
  end

  def self.solr_delete_all(solr)
    solr.delete_by_query '*:*'
  end

  def self.solr_update(solr, id, loc_id, name, type_name, icon_group_id,
                       longitude, latitude,
                       city, state_two_letter, zip, country
                       )
    geohash_str = GeoHash.encode latitude, longitude, GEOHASH_PRECISION
    solr = RSolr.connect :url => SOLR_URL
    document = {"id"=> loc_id, "org_id" => id, "name"=> name,
      "type_name" => type_name,
      "icon_group_id" => icon_group_id,
      "longitude" => longitude, "latitude" => latitude,
      "location" => latitude.to_s + ", " + longitude.to_s,
      "state_two_letter" => state_two_letter,
      "zip" => zip,
      "city" => city,
      "country" => country
    }
    1.upto(GEOHASH_PRECISION) do |i|
      document["geohash_#{i}"] = geohash_str[0..(i-1)]
    end
    response = solr.add [document]
  end

end
