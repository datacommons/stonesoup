ActionController::Routing::Routes.draw do |map|
  map.resources :organizations_people
  map.resources :people
  map.resources :access_rules
  map.resources :member_orgs
  map.resources :sectors
  map.resources :org_types
  map.resources :product_services
  map.resources :locations
  map.resources :organizations
  #map.resources :plumbing

  # The priority is based upon order of creation: first created -> highest priority.
  
  # Sample of regular route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  # map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # You can have the root of your site routed by hooking up '' 
  # -- just remember to delete public/index.html.
  map.connect '', :controller => "search"

  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  #map.connect ':controller/service.wsdl', :action => 'wsdl'

  # workaround for not having access to ferret_server
  map.connect 'plumbing/org', :controller => 'plumbing', :action => 'org'
  map.connect 'plumbing/ppl', :controller => 'plumbing', :action => 'ppl'
  map.connect 'plumbing/loc', :controller => 'plumbing', :action => 'show'
  map.connect 'plumbing/index', :controller => 'plumbing', :action => 'index'

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
