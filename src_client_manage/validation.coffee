validate = (presentation) ->
  console.log presentation
  
  if !presentation.title? or $.trim(presentation.title) is ""
    return new Error("Title is mandatory")
  
  return
  
@presentzorg.validation = validate