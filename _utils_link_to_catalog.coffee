"use strict"

orient = require "orientdb"
assert = require "assert"

catalog_id = process.argv[2]
presentation_id = process.argv[3]

server = new orient.Server
  host: "localhost"
  port: 2424

db = new orient.GraphDb "presentz", server,
  user_name: "admin"
  user_password: "admin"

db.open (err) ->
  assert(!err, err)

  db.command "select from OGraphVertex where _type = 'catalog' and id = '#{catalog_id}'", (err, results) ->
    assert(!err, err)
    
    assert(results.length is 1)
    
    console.log arguments
    
    catalog = results[0]
    
    db.command "select from OGraphVertex where _type = 'presentation' and id = '#{presentation_id}'", (err, results) ->
      assert(!err, err)

      assert(results.length is 1)
  
      console.log arguments
      
      presentation = results[0]

      db.createEdge presentation, catalog, { label: "part_of" }, (err) ->
        assert(!err, err)
        
        db.close()