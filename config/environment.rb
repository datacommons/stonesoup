# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.2.2'

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

require "ruport"
require "ruport/acts_as_reportable"

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence those specified here
  
  # Skip frameworks you're not going to use
  # config.frameworks -= [ :action_web_service, :action_mailer ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level 
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  config.action_controller.session = {
    :session_key => '_dcp_session',
    :secret      => '2f545e9d2a7d6df0b893695b2b2f34bb9'
  }

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake db:sessions:create')
  # config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper, 
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc
  
  # See Rails::Configuration for more options
  config.gem "geokit"

  config.load_paths << "#{RAILS_ROOT}/app/reports"
end

# Add new inflection rules using the following format 
# (all these examples are active by default):
# Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

# Include your application configuration below

# UTF-8 Support (multibyte support)
$KCODE = 'u'
require 'jcode'

# This is your yahoo application key for the Yahoo Geocoder.
# See http://developer.yahoo.com/faq/index.html#appid
# and http://developer.yahoo.com/maps/rest/V1/geocode.html
GeoKit::Geocoders::YAHOO='REPLACE_WITH_YOUR_YAHOO_KEY'
    
# This is your Google Maps geocoder key. 
# See http://www.google.com/apis/maps/signup.html
# and http://www.google.com/apis/maps/documentation/#Geocoding_Examples

if ENV['RAILS_ENV'] == 'development'
   # the key given here is appropriate for http://localhost/
   #GeoKit::Geocoders::GOOGLE='ABQIAAAATL4sfiJFXUFfYtomrKYcMRT2yXp_ZAY8_ufC3CFXhHIE1NvwkxSgdzNqmW5nuNCkPicJS8sOhHTE4w'
   # Here's a key for http://localhost:3000
   GeoKit::Geocoders::GOOGLE="ABQIAAAA3HdfrnxFAPWyY-aiJUxmqRTJQa0g3IQ9GZqIMmInSLzwtGDKaBQ0KYLwBEKSM7F9gCevcsIf6WPuIQ"    
elsif ENV['RAILS_ENV'] == 'production'
   # Here's a key for http://temp-dcp.gaiahost.net/ 
   #GeoKit::Geocoders::GOOGLE="ABQIAAAATL4sfiJFXUFfYtomrKYcMRTiunT2uSmbcIF9JcYA7tUAKz8ykBQrDga0HatVT0swrunnV3FDzdK4QA" 
   # Here's a key for http://proto.find.coop
   #GeoKit::Geocoders::GOOGLE="ABQIAAAATL4sfiJFXUFfYtomrKYcMRSRQZaHZSfXeR81hnlCJRsRo2MAKhSQQPObczixZftaBkuHNkPBTHA0XQ";
   # Here's a key for http://find.coop
   GeoKit::Geocoders::GOOGLE="ABQIAAAATL4sfiJFXUFfYtomrKYcMRQWkLFHAQFNAudcyCckITx1xAPkLBSrTBBG0d4ePeNRV85ri4suvrDeCg"
end

# This is your username and password for geocoder.us.
# To use the free service, the value can be set to nil or false.  For 
# usage tied to an account, the value should be set to username:password.
# See http://geocoder.us
# and http://geocoder.us/user/signup
GeoKit::Geocoders::GEOCODER_US=false 

# This is your authorization key for geocoder.ca.
# To use the free service, the value can be set to nil or false.  For 
# usage tied to an account, set the value to the key obtained from
# Geocoder.ca.
# See http://geocoder.ca
# and http://geocoder.ca/?register=1
GeoKit::Geocoders::GEOCODER_CA=false

# This is the order in which the geocoders are called in a failover scenario
# If you only want to use a single geocoder, put a single symbol in the array.
# Valid symbols are :google, :yahoo, :us, and :ca.
# Be aware that there are Terms of Use restrictions on how you can use the 
# various geocoders.  Make sure you read up on relevant Terms of Use for each
# geocoder you are going to use.
GeoKit::Geocoders::PROVIDER_ORDER=[:google,:us]

require "will_paginate"

email_config_file = "#{RAILS_ROOT}/config/email.yml"
if FileTest.exist?(email_config_file)
  email_settings = YAML::load(File.open(email_config_file))
  ActionMailer::Base.smtp_settings = email_settings[RAILS_ENV] unless email_settings[RAILS_ENV].nil?
end


# add "essentially the same" operator to relevant classes, for the change_message method in Common
class String
  def same_value?(other)
    if other.blank?
      return self.empty?  #same as self.blank? since self is obviously not nil
    end
    self == other.to_s
  end
end

class Numeric
  def same_value?(other)
    if (other.is_a?(String) and other.blank?) or other.nil?
      return self.zero?
    end
    self == other.to_i
  end
end

class Float
  def same_value?(other)
    if (other.is_a?(String) and other.blank?) or other.nil?
      return self.zero?
    end
    self == other.to_s.to_f
  end
end

class Date
  def same_value?(other)
    if (other.is_a?(String) and other.blank?) or other.nil?
      return self.jd.zero?
    end
    self === Date.parse(other.to_s)
  end
end

class Time
  def same_value?(other)
    if (other.is_a?(String) and other.blank?) or other.nil?
      return self.to_i.zero?
    end
    self === Time.parse(other.to_s)
  end
end

class DateTime
  def same_value?(other)
    if (other.is_a?(String) and other.blank?) or other.nil?
      return self.jd.zero?
    end
    self === DateTime.parse(other.to_s)
  end
end

class TrueClass
  def same_value?(other)
    if (other.is_a?(String) and other.blank?) or other.nil?
      return false
    end
    self == Common::value_to_boolean(other)
  end
end

class FalseClass
  def same_value?(other)
    if (other.is_a?(String) and other.blank?) or other.nil?
      return true
    end
    self == Common::value_to_boolean(other)
  end
end

class DateTime
  def datepart
    Date.new(self.year, self.month, self.mday)
  end
end

class Time
  def datepart
    Date.new(self.year, self.month, self.mday)
  end
end
