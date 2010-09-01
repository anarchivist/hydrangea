ActionController::Routing::Routes.draw do |map|  
  map.resources :collections 
  map.connect 'collections/:id', :controller=>:collections, :actions=>:show
 
  map.resources :doc_viewer
  
  map.json 'doc_viewer/:id/json', :controller=>:doc_viewer, :action=>:show_json
  map.pdf 'doc_viewer/:id/document.pdf', :controller=>:doc_viewer, :action=>:show_pdf
  map.pages 'doc_viewer/:id/:page', :controller=>:doc_viewer, :action=>:show_page
  map.full_screen 'doc_viewer/:id', :controller=>:doc_viewer, :action=>:show
  

  # Load Blacklight's routes and add edit_catalog named route
  Blacklight::Routes.build map
  map.edit_catalog 'catalog/:id/edit', :controller=>:catalog, :action=>:edit
  
  #map.root :controller => 'collections', :action=>'index'
  # map.resources :assets do |assets|
  #   assets.resources :downloads, :only=>[:index]
  # end
  map.resources :get, :only=>:show  
  map.resources :webauths, :protocol => ((defined?(SSL_ENABLED) and SSL_ENABLED) ? 'https' : 'http')
  map.login "login", :controller => "webauth_sessions", :action => "new"
  map.logout "logout", :controller => "webauth_sessions", :action => "destroy"
end
