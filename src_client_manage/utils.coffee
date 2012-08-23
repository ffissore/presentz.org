url_regexp = /(ftp|http|https):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/

is_url_valid = (url) ->
  url_regexp.test(url)

@presentzorg.is_url_valid = is_url_valid