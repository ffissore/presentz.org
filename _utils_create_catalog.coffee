orient = require "orientdb"
assert = require "assert"

server = new orient.Server
  host: "localhost"
  port: 2424

db = new orient.GraphDb "presentz", server,
  user_name: "admin"
  user_password: "admin"

db.open (err) ->
  assert(!err, err)
  
  db.loadRecord "#6:0", (err, root) ->
    assert(!err, err)

    db.loadRecord "#6:1", (err, user) ->
      assert(!err, err)

      catalog =
        name: "Toolbox Coworking"
        logo: "/assets/codemotion12/banner130x130.gif"
        website: "http://www.toolboxoffice.it/"
        _type: "catalog"
        id: "toolbox"
        
      db.createVertex catalog, (err, catalog) ->
        assert(!err, err)
    
        db.createEdge root, catalog, { label: "catalog" }, (err) ->
          assert(!err, err)
          
          db.createEdge user, catalog, { label: "admin_of" }, (err) ->
            assert(!err, err)
            
            db.close()