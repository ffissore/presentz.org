###
GET home page.
###

exports.index= (req, res) ->
  res.render "index", 
    title: "Express"
  
exports.hello_user= (req, res) ->
  res.render "hello", 
    username: req.params.name
    title: "ciao!"