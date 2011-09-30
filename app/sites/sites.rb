require 'site'
Dir["#{File.dirname(__FILE__)}/*.rb"].each do |file|
  basename = File.basename(file, '.rb')
  unless ['site','sites'].include?(basename)
    require "#{basename}"
  end
end

Site.scan
