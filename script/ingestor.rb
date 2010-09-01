#!/usr/bin/env ruby
require 'rubygems'
require 'tempfile'
require  File.join(File.dirname(__FILE__), '../config/environment.rb')

RAILS_DEFAULT_LOGGER.auto_flushing = 1

class Ingestor

  def initialize(directory=nil)

     Module.const_set("AimsDocument", AimsDocument)
     ###### The directory to be processed ######
     @directory = directory

     ###### Configuration Stuff Here #######
     @fedora_user = 'fedoraAdmin'
     @fedora_pass = 'fedoraAdmin'
     @fedora_uri = "http://#{@fedora_user}:#{@fedora_pass}@hydra-aims-dev.stanford.edu/fedora/"
     @fedora_ns = "druid"
     @solr_uri =  "http://hydra-aims-dev.stanford.edu/solr/"

     ###### Register the Repos #######
     # => http://projects.mediashelf.us/wiki/active-fedora/ActiveFedora_Console_Tour

     ActiveFedora::SolrService.register(@solr_uri, :verify_mode=>:none)
     Fedora::Repository.register(@fedora_uri)

     ###### You can keep a list of file extension to be ingested here, with a specification of their control group #####
     ###### Typically, most files are ingested with a control group "M" (managed). XML is often stored as "X" (inline XML), but
     ###### can also be stored as "M". Yeah.
     # => http://www.fedora-commons.org/documentation/3.0b1/userdocs/digitalobjects/objectModel.html

     ### To configure this, there are two hashes, which you can define file extensions to match a DS label/id.
     ### The syntax is {".pdf" => { "id" => "pdf", "label" => "A PDF of the Document"}}
     ### If there is no label or id, the base file name (minus extension) is used.
     ### Since IDs must be unique, If there are multiple datastreams with the same extension,
     ### the first file will be given the ID, with the following files using their filenames as their IDs.
     ### NOT USING THESE FOR AIMS INGESTOR
     #@managed = {".pdf" => { "id" => "PDF", "label" =>"Document PDF"} , ".tiff" => "", ".jpg" => { "label" => "Thumbnail"}, ".xml" => ""}
     #@inline = {".dc" => {'id' => 'dublin_core', "label" => "Metadata"}}
   end #initialize

  
  
  

     def process()
       if @directory.nil?
          puts "Fedora Ingestor: This file ingests subdirectories into Fedora as objects. Each of the files are assigned as their own managed datastreams."
          puts "To run the script, you must include a base directory with you objects."
          puts "like so=>    $:  ./ingestor.rb /tmp/objects"
       elsif File.exists?(@directory)
          Dir["#{@directory}/*"].each do |obj|
            ingest_object(obj) if File.directory?(obj)
          end #do
       else
         puts "Error: #{@directory} does not exists."
        end #if @directory.nil?
     end #process

     #
     #  This method creates a "Managed" datastream object.
     #  Just realized spaces in file names cause problems in the ID/Label, so there's hokey quick fix for that.
     def create_file_ds(f, id= nil, label=nil)
       puts "creating file ds for #{f} "
       if id.nil? || id.empty?
         id = File.basename(f, File.extname(f)).gsub(" ", "-")
       end
       if label.nil? || label.empty?
         label = File.basename(f, File.extname(f)).gsub(" ", "-")
       end

       ActiveFedora::Datastream.new(:dsID=>id, :controlGroup=>"M" , :blob=>File.open(f), :dsLabel=>label)

     end  #create_file_ds

     #
     # This method creates an "Inline" datastream object
     #
     def create_inline_ds(f, id= nil, label=nil)
       puts "creating inline ds for #{f} "
       if id.nil?
         id = File.basename(f, File.extname(f)).gsub(" ", "-")
       end
       if label.nil?
         label = File.basename(f, File.extname(f)).gsub(" ", "-")
       end
       #this helps format the XML a bit
       xml = Nokogiri::XML(open(f))
       ds = ActiveFedora::Datastream.new(:dsID=>id, :controlGroup=>"X", :dsLabel=>label)
       ds.content = xml.to_xml
       return ds
     end  #create_inline_ds


     # This method is passed a directory, makes a new fedora object, then makes datastreams of each of the files in the directory. 

     def ingest_object(obj)

       # Gets a new PID
       pid = Nokogiri::XML(open(@fedora_uri + "/management/getNextPID?xml=true&namespace=#{@fedora_ns}", {:http_basic_authentication=>[@fedora_user, @fedora_pass]})).xpath("//pid").text
       
       #testing stuff
       #pid = "druid:1"
       #fedora_obj = AimsDocument.load_instance(pid)
       #fedora_obj.delete
       
       fedora_obj = AimsDocument.new(:pid => pid)
       fedora_obj.label = File.basename(obj)
     
       print obj + " ===> "
       # now glob the object directory and makes datastreams for each of the files and add them as datastream to the fedora object.
        fedora_obj.save
       
        dsid = 'rightsMetadata'
        xml_content = fedora_obj.datastreams_in_memory[dsid].content
        ds = Hydra::RightsMetadata.from_xml(xml_content)
        pid = fedora_obj.pid
        ds.pid = pid
        ds.dsid = dsid
        fedora_obj.datastreams_in_memory[dsid] = ds
        permissions = {"group"=>{"public"=>"read", "archivist" => "edit", "researcher" => "read", "patron" => 'read', "donor" => 'edit' }, "person" => {"archivist1" => "edit"}}
        ds.update_permissions(permissions)
         permissions = {"group" => {"public"=>"read"}}
         ds.update_permissions(permissions)
        
         fedora_obj.save
       
       Dir["#{obj}/**/**"].each do |f|
         
         #damn OS X spotlight. 
         unless f.include?('DS_Store')
          
          # text files and jp2000s get added as datastreams in the object. the wordperfect files get added as their own objects
          if f =~ /(.*)\.(txt)/
             fedora_obj.add_datastream(create_file_ds(f, File.basename(f), File.basename(f)))
           
          elsif f =~ /(.*)\.(pdf)/
             fedora_obj.add_datastream(create_file_ds(f, 'pdf', "#{File.basename(f)}.pdf"))
          elsif f =~  /(.*)\.(jp2)/
             jp2_dir = File.join('/tmp', fedora_obj.pid.gsub("druid:", "druid_"))
             FileUtils.mkdir_p(jp2_dir) unless File.directory?(jp2_dir)
             FileUtils.move(f, jp2_dir, :verbose => true)
            
          else   
             cpid = Nokogiri::XML(open(@fedora_uri + "/management/getNextPID?xml=true&namespace=#{@fedora_ns}", {:http_basic_authentication=>[@fedora_user, @fedora_pass]})).xpath("//pid").text
             # testing stuff
             #cpid = "druid:2"
             #child_obj = FileAsset.load_instance(cpid)  
             #child_obj.delete

             child_obj = FileAsset.new(:pid => cpid)
             child_obj.label = File.basename(f)
             dc = child_obj.datastreams['descMetadata']
             dc.extent_values << File.size(f)
           
           
             fedora_obj.add_relationship(:has_part, child_obj )
             fedora_obj.add_relationship(:has_collection_member, child_obj)
             puts "processing:#{f} for objectID #{cpid}"
             ext = File.extname(f)
             id = "DS1"
             label = File.basename(f)
             child_obj.add_datastream(create_file_ds(f, id, label ))
             child_obj.save
             print f + "\n"
          end #if
         end #unless
       end #dir
        
         dm = fedora_obj.datastreams["descMetadata"]
         prop = fedora_obj.datastreams["properties"]
         
         prop.collection_values << "Steven J. Gould"
         prop.pages_values << number_of_pages(fedora_obj)

         dm.source_values << File.basename(obj)
         dm.type_values << "Document"
         dm.format_values << "5.25 inch floppy diskettes"
         dm.isPartOf_values = ["Full House"]
         dm.title_values << File.basename(obj)

        dm.save
        prop.save
        fedora_obj.save
        
        solr_doc = fedora_obj.to_solr
        solr_doc <<  Solr::Field.new( :discover_access_group_t => "public" )
        ActiveFedora::SolrService.instance.conn.update(solr_doc )
     
    
      
     end #ingest_object


     # this makes the json for the nytimes book reader app
    

    #this method gets the number of pages for a document
    def number_of_pages(fedora_obj)
      len = []
      fedora_obj.datastreams.keys.each do |x|
        len << x if x.include?('.txt')
      end
      len.length
    end #number_of_pages

   end #class

   #========== This is the equivalent of a java main method ==========#
   if __FILE__ == $0
     ingestor = Ingestor.new(ARGV[0])
     ingestor.process
   end
