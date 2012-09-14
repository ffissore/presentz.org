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

  it "should parse float and round", () ->
    assert.equal 8.12, utils.my_parse_float("8.1234")
    assert.equal 8.123, utils.my_parse_float("8.1234", 1000)
    assert.equal 8.12, utils.my_parse_float(8.1234)