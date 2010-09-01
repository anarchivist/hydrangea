require 'hydra'
class AimsDocument < ActiveFedora::Base

    
    include Hydra::ModelMethods 

    has_relationship "parts", :is_part_of, :inbound => true
    
    
    has_metadata :name => "rightsMetadata", :type => Hydra::RightsMetadata 
    
    
    # These are all the properties that don't quite fit into Qualified DC
    # Put them on the object itself (in the properties datastream) for now.
    has_metadata :name => "properties", :type => ActiveFedora::MetadataDatastream do |m|
      m.field "note", :text  
      m.field "access", :string
      m.field "archivist_tag", :string
      m.field "donor_tag", :string
      m.field 'collection', :string
      m.field 'depositor', :string
      m.field 'pages', :string
    end
    
    has_metadata :name => "stories", :type=>ActiveFedora::MetadataDatastream do |m|
      m.field "story", :text
    end
    
    has_metadata :name => "descMetadata", :type => ActiveFedora::QualifiedDublinCoreDatastream do |m|
      # Default :multiple => true
      #
      # on retrieval, these will be pluralized and returned as arrays
      #
      # aimint to use method-missing to support calling methods like
      
      # Setting new Types for dates and text content
      #m.field "creation_date", :string, :xml_node => "date"
      #m.field "abstract", :text, :xml_node => "abstract"
      #m.field "rights", :text, :xml_node => "rights"
      
      # Setting up special named fields
      #m.field "subject_heading", :string, :xml_node => "subject", :encoding => "LCSH" 
      #m.field "spatial_coverage", :string, :xml_node => "spatial", :encoding => "TGN"
      #m.field "temporal_coverage", :string, :xml_node => "temporal", :encoding => "Period"
      #m.field "type", :string, :xml_node => "type", :encoding => "DCMITYPE"
    end


      # Inserts a new contributor (mods:name) into the mods document
      # creates contributors of type :person, :organization, or :conference
      def insert_contributor(type, opts={})
        case type
        when "author"
          nodelength = self.datastreams['descMetadata'].creator_values.length
          node = Nokogiri::XML("<creator></creator>").root
          self.datastreams['descMetadata'].creator_values << ""
           self.datastreams['descMetadata'].dirty = true
        when "contributor"
          nodelength = self.datastreams['descMetadata'].contributor_values.length
          node = Nokogiri::XML("<contributor></contributor>").root
          self.datastreams['descMetadata'].contributor_values << ""
           self.datastreams['descMetadata'].dirty = true
        else
          ActiveFedora.logger.warn("#{type} is not a valid argument for AimsDocument.insert_contributor")
          node = nil
          index = nil
        end

       
        return node, index
      end

      # Remove the contributor entry identified by @contributor_type and @index
      def remove_contributor(contributor_type, index)
        self.retrieve( {contributor_type.to_sym => index.to_i} ).first.remove
        self.dirty = true
      end
   
       def self.medium_choices
          ["Paper Document","Paper","Instructional Material","Proposal", "Reprint","Correspondence"]
        end
   
end