module GEOCODE_CACHE
  def self.lookup(address)
    result = GEOCODE_CACHE_DB::Geocode_Cache_Entry.first(
               :conditions => {:address => address} )
    if result == nil
      return nil
    else
      return [result.latitude, result.longitude]
    end
  end

  def self.insert(address, longitude, latitude, uid, oid, bid)
    a = GEOCODE_CACHE_DB::Geocode_Cache_Entry.new( :address => address,
                                                   :longitude => longitude,
                                                   :latitude => latitude,
                                                   :uid => uid,
                                                   :oid => oid,
                                                   :bid => bid)
    a.save!
  end

end
