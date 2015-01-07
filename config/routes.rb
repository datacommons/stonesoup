Stonesoup::Application.routes.draw do
  # match 'global_router' => '#index', :as => :filter
  match 'tags/search' => 'tags#search'
  match 'tags/search2' => 'tags#search2'
  match 'tags/dashboard' => 'tags#dashboard'
  match 'tags/update_identities' => 'tags#update_identities'
  match 'page/:id' => 'search#page'
  resources :data_sharing_orgs
  resources :legal_structures
  resources :organizations_people
  resources :people
  resources :access_rules
  match 'set-visibility/:status/:token' => 'access_rules#set_org_visibility'
  resources :member_orgs
  resources :sectors
  resources :org_types
  resources :product_services
  resources :locations
  resources :organizations
  resources :tags
  resources :tag_worlds
  resources :tag_contexts
  match '' => 'search#index'
  match 'feed' => 'search#feed', :as => :feed
  match 'recent' => 'search#recent', :as => :recent
  match 'help' => 'search#help', :as => :help
  match 'plumbing/org' => 'plumbing#org'
  match 'plumbing/ppl' => 'plumbing#ppl'
  match 'plumbing/loc' => 'plumbing#show'
  match 'plumbing/index' => 'plumbing#index'
  match 'plumbing/email' => 'plumbing#email'
  match '/:controller(/:action(/:id))'
  match '*path' => 'search#not_found', :as => :error
end
