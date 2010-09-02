module DocViewerHelper


   

  def make_json(fedora_obj)
      dm = fedora_obj.datastreams["descMetadata"]
      prop = fedora_obj.datastreams["properties"]
      
      h = Hash.new { |l, k| l[k] = Hash.new(&l.default_proc) }
      
      h["title"] = dm.title_values.first
      h["annotations"] =   [ {"title" => "An Example Annotation",
           "content" => "",
           "page"=>1,
           "location"=>{20, 20, 20, 20}}
        ]
      h["resources"]["related_story"] = "" 
      h["resources"]["page"]["text"] = "http://#{request.env['HTTP_HOST']}/doc_viewer/#{fedora_obj.pid}/page-{page}"
      h["resources"]["page"]["image"] = "http://salt-prod.stanford.edu:8080/adore-djatoka/resolver?url_ver=Z39.88-2004&rft_id=http://hydra-dev.stanford.edu/#{fedora_obj.pid.gsub('druid:', '')}/page-{page}.jp2&svc_id=info:lanl-repo/svc/getRegion&svc_val_fmt=info:ofi/fmt:kev:mtx:jpeg2000&svc.format=image/jpeg&svc.level={size}&svc.rotate=0" 
      h["resources"]["pdf"] = "http://#{request.env['HTTP_HOST']}/doc_viewer/#{fedora_obj.pid}/document.pdf"
      h["resources"]["search"] = "http://#{request.env['HTTP_HOST']}/doc_viewer/#{fedora_obj.pid}/search?q={query}"
      #h["sections"] = [{}]
      h["id"] = fedora_obj.pid
      h["pages"] = prop.pages_values.first.to_i
      h["description"] = dm.abstract_values.first
      h.to_json
        
  end #mke_json


   def render_json(json, options={})
      callback, variable = params[:callback], params[:variable]
      response = begin
        if callback && variable
          "var #{variable} = #{json};\n#{callback}(#{variable});"
        elsif variable
          "var #{variable} = #{json};"
        elsif callback
          "#{callback}(#{json});"
        else
          json
        end
      end
      render({:content_type => 'application/json', :json => response}.merge(options))
    end
    
   def render_text(text, options={})
        callback, variable = params[:callback], params[:variable]
        response = begin
          if callback && variable
            "var #{variable} = #{text};\n#{callback}(#{variable});"
          elsif variable
            "var #{variable} = #{text};"
          elsif callback
            "#{callback}(#{text});"
          else
            text
          end
        end
        render({:content_type => 'text/html', :text => response}.merge(options))
      end
    
    
      
      
end