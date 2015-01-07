require File.expand_path('../boot', __FILE__)

require 'rails/all'

Bundler.require(:default, Rails.env) if defined?(Bundler)

module Stonesoup
  class Application < Rails::Application
    config.autoload_paths += [config.root.join('lib')]
    config.encoding = 'utf-8'
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
      :key => '_dcp_session',
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
  
    # this gem needs to be imported at this point so the rails plugin
    # geokit-rails can load
    require "geokit"
    require "google-v3-geocoder"
    Geokit::Geocoders::provider_order = [:google_v3,:us]
  
    config.autoload_paths << "#{RAILS_ROOT}/app/reports"
    config.autoload_paths << "#{RAILS_ROOT}/app/sites"
  
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales','**', '*.{rb,yml}')]
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
  # $KCODE = 'u'
  # require 'jcode'
  
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
  
  class ActiveRecord::Base
    def get_value_hash
      oldvalues = Hash[*self.class.columns.reject { |c| 
          ['id', 'created_at', 'created_by_id', 'updated_at', 'updated_by_id'].include?(c.name)
        }.collect { |c| 
          [c.name, self.send(c.name)]
        }.flatten]
      if self.class.respond_to?('update_notification_has_one_columns')
        hasone_columns = self.class.update_notification_has_one_columns()
      else
        hasone_columns = []
      end
      hasone_columns.each do |hasone|
        unless self.respond_to?(hasone)
          logger.error("ERROR: #{self.class} has no method '#{hasone}' -- please update #{self.class}.update_notification_has_one_columns()")
          next
        end
        oldvalues.delete(hasone + '_id')
        value = self.send(hasone)
        oldvalues[hasone] = value.to_s unless value.nil?
      end
      return oldvalues
    end
  end
end
