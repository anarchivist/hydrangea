module ApplicationHelper
  include Stanford::SearchworksHelper
  #include Stanford::SolrHelper # this is already included by the SearchworksHelper
  include HydraHelper
  
  def application_name
    'AIMS Demo'
  end
  
  def get_data_with_linked_label(doc, label, field_string, opts={})
   
    (opts[:default] and !doc[field_string]) ? field = opts[:default] : field = doc[field_string]
    delim = opts[:delimiter] ? opts[:delimiter] : "<br/>"
    if doc[field_string]
      text = "<dt>#{label}</dt><dd>"
      if field.respond_to?(:each)
        text += field.map do |l| 
          linked_label(l, field_string)
        end.join(delim)
      else
        text += linked_label(field, field_string)
      end
      text += "</dd>"
      text
    end
  end
  
  def display_for_ead_node( node_name , ead_description=@descriptor ) 
    xpath_query = "//archdesc[@level=\"collection\"]/#{node_name}"
    response = ""
    response << "<dl>"
    if !ead_description.xpath( xpath_query + "/head" ).first.nil? && !ead_description.xpath( xpath_query + "/p" ).first.nil?
      response << "<dt> #{ead_description.xpath( xpath_query + "/head" ).first.content} </dt>"
      response << "<dd>"
      ead_description.xpath( xpath_query + "/p" ).each do |xp|
        response << "#{xp.content}<br/><br/>"
      end
      response <<  "</dd>"
      response << "</dl>"
    end
    if node_name == "controlaccess"
      response << "<ul>"
      ead_description.xpath( xpath_query + "/*[@source]" ).each do |subject|
        response << "<li>[#{subject.attribute("source")}]  #{subject.content}</li>"
      end
    end
    return response
  end
  
  
  
  def linked_label(field, field_string)
    link_to(field, add_facet_params(field_string, field).merge!({"controller" => "catalog", :action=> "index"}))
  end
  def link_to_document(doc, opts={:label=>Blacklight.config[:index][:show_link].to_sym, :counter => nil,:title => nil})
    label = case opts[:label]
      when Symbol
        doc.get(opts[:label])
      when String
        opts[:label]
      else
        raise 'Invalid label argument'
      end

    if label.blank?
      label = doc[:id]
    end
    
    link_to_with_data(label, catalog_path(doc[:id]), {:method => :put, :data => {:counter => opts[:counter]},:title=>opts[:title]})
  end
end
