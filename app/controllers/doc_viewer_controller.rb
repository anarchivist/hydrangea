require 'mediashelf/active_fedora_helper'

class DocViewerController < ApplicationController 
  
 # layout "show_full_screen", :only=>[:show_full_screen]
  include DocViewerHelper
  include Blacklight::CatalogHelper
  include Hydra::RepositoryController
  include Hydra::AccessControlsEnforcement
    include Hydra::FileAssetsHelper  
  before_filter :require_solr, :require_fedora

  def show

     enforce_viewing_context_for_show_requests
     af_base = ActiveFedora::Base.load_instance(params[:id])
     the_model = ActiveFedora::ContentModel.known_models_for( af_base ).first
     if the_model.nil?
       the_model = DcDocument
     end
     @document_fedora = the_model.load_instance(params[:id])
    
    
  end

  def show_page
     @fedora_doc =  ActiveFedora::Base.load_instance(params[:id]) 
     render_text @fedora_doc.datastreams["#{params[:page]}.txt"].content
  end
    
  def show_json
       enforce_viewing_context_for_show_requests
        af_base = ActiveFedora::Base.load_instance(params[:id])
        the_model = ActiveFedora::ContentModel.known_models_for( af_base ).first
        if the_model.nil?
          the_model = DcDocument
        end
        @document_fedora = the_model.load_instance(params[:id])
       render_json make_json(@document_fedora)
  end #show_json
    
        
  def show_pdf
  
    enforce_viewing_context_for_show_requests
    af_base = ActiveFedora::Base.load_instance(params[:id])
      the_model = ActiveFedora::ContentModel.known_models_for( af_base ).first
      if the_model.nil?
        the_model = DcDocument
      end
      @document_fedora = the_model.load_instance(params[:id])
      
       if @document_fedora.datastreams_in_memory.include?("pdf")
           datastream = @document_fedora.datastreams_in_memory["pdf"]
           send_data datastream.content, :filename=>datastream.label, :type=>datastream.attributes["mimeType"]
      else
        flash[:notice]= "You do not have sufficient access privileges to download this document, which has been marked private."
        redirect_to(:action => 'index', :q => nil , :f => nil)
      end
  end
  
end
