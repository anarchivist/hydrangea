class CollectionsController < CatalogController
  
  before_filter :retrieve_descriptor, :only =>[:index, :show]
  
  # get search results from the solr index
  def index
       params = {:qt=>"dismax",:q=>"*:*",:rows=>"0",:facet=>"true", :facets=>{:fields=>Blacklight.config[:facet][:field_names]}}
       @facet_lookup = Blacklight.solr.find params
       @response = @facet_lookup
      @filters = params[:f] || []
       respond_to do |format|
         format.html { save_current_search_params }
         format.rss  { render :layout => false }
       end
       rescue RSolr::RequestError
         logger.error("Unparseable search error: #{params.inspect}" ) 
         flash[:notice] = "Sorry, I don't understand your search." 
         redirect_to :action => 'index', :q => nil , :f => nil
       rescue 
         logger.error("Unknown error: #{params.inspect}" ) 
         flash[:notice] = "Sorry, you've encountered an error. Try a different search." 
         redirect_to :action => 'index', :q => nil , :f => nil
  end
  
  def show
       params = {:qt=>"dismax",:q=>"*:*",:rows=>"0",:facet=>"true", :facets=>{:fields=>Blacklight.config[:facet][:field_names]}}
       @facet_lookup = Blacklight.solr.find params
       @response = @facet_lookup
       @filters = params[:f] || []
     respond_to do |format|
       format.html { save_current_search_params }
       format.rss  { render :layout => false }
     end
  
   end
   
  private
  
  # override this method to do nothing in this controller
  def enforce_viewing_context_for_show_requests    
  end
  
  def retrieve_descriptor
    # We should be grabbing this from the collection_facet param, but there's only one collection so its hard-coded.
    #collection_id = params["gould"]
    collection_id = "gould"
    @descriptor = Descriptor.register(collection_id)
    #@descriptor = Descriptor.retrieve( collection_id )
  end
  
end
