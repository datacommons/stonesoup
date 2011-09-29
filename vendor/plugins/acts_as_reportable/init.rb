require "ruport"
require "ruport/acts_as_reportable"
	
ActiveRecord::Base.send :include, Ruport::Reportable
