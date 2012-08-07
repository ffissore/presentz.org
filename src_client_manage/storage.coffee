jQuery () ->
  originalMethod = Backbone.sync

  Backbone.sync = (method, model, [options]) ->
    
    console.log originalMethod.call(Backbone, method, model, options)

    url = model.url_map[method]
    
    return options.error("Unknown method #{method}") if !url?
    
    switch method
      when "read" 
        $.get url, ->
          
      else options.error("Unknown method #{method}")
    