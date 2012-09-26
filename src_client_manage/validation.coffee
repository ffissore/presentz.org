"use strict"

validate = (presentation, options) ->
  return if options.skip_validation
  
  if !presentation.title? or $.trim(presentation.title) is ""
    return new Error("Title is mandatory")
  
  return
  
@validation = validate