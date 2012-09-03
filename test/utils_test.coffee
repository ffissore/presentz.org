assert = require "assert"
utils = require("../utils")
_s = require "underscore.string"

describe "Utils", () ->

  it "should make nice IDs", () ->
    id = utils.generate_id("Cloud Testing di applicazioni web con Python ed Amazon EC2")
    assert _s.endsWith(id, "_cloud_testing_applicazioni_web_con_python_amazon_ec2")

    id = utils.generate_id("Cloud Testing di applicazioni web con Python ed Amazon EC2 ed")
    assert _s.endsWith(id, "_cloud_testing_applicazioni_web_con_python_amazon_ec2")
  
  it "should ignore empty titles", () ->
    id = utils.generate_id()
    assert id.length is 10
    id = utils.generate_id("")
    assert id.length is 10
    
  it "should find valid URLs", () ->
    assert utils.is_url_valid("http://presentz.org/assets/jugtorino/201102_akka/201105071337135616730.swf")