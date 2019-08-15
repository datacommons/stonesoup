#!./script/runner

require 'nsf_db'

GOOGLE_LIMIT_PER_SECOND = 10
GOOGLE_LIMIT_PER_DAY = 2500-10 # is really 2500, but assume other testing

n = 0
big_n = 0

# should be in a lib...
def fix_null_and_blank(a)
  if a == "NULL" or a == ""
    nil
  else
    a
  end
end

NSF_DB::Location.all().each do |e|
  if fix_null_and_blank(e.city) != nil
    l = Location.new(:note => e.location_name,
                     :physical_address1 => fix_null_and_blank(e.address),
                     :physical_address2 => fix_null_and_blank(e.address2),
                     :latitude => nil,
                     :longitude => nil,
                     :physical_city => e.city,
                     :physical_state => fix_null_and_blank(e.state),
                     :physical_zip => fix_null_and_blank(e.zipcode),
                     :physical_country => e.country )
    address_str = l.to_s
    if GEOCODE_CACHE::lookup(address_str) == nil

      if big_n == GOOGLE_LIMIT_PER_DAY
        puts "we've reached our daily limit with Google, going " + \
        "to sleep for a day!"
        sleep(60*60*24 + 2*60)
        n = 0
        big_n = 0
      end
      if n == GOOGLE_LIMIT_PER_SECOND
        sleep(1)
        n = 0
      end
      google_location=GeoKit::Geocoders::GoogleGeocoder3.geocode(address_str)
      coords = google_location.ll.scan(/[0-9\.\-\+]+/)
      n += 1
      big_n += 1
      if coords.length == 2
        GEOCODE_CACHE::insert(address_str, coords[1], coords[0])
      else
        puts address_str + " for lid " + e.lid.to_s + " not found by google"
      end
    end
  else
    puts "lid " + e.lid.to_s + " " + e.location_name + " skipped, no city " + e.city
  end
end

