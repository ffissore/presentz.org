"use strict"

assert = require "assert"
xregexp = require("../node_modules/xregexp/xregexp-all.js")
global.XRegExp = xregexp.XRegExp

utils = require("../utils")
_s = require "underscore.string"
accent_folding = require("accent-folding").accent

describe "Utils", () ->
  it "should make nice IDs", () ->
    id = utils.generate_id(accent_folding.accent_fold, "Cloud Testing di applicazioni web con Python ed Amazon EC2")
    assert _s.startsWith(id, "cloud_testing_applicazioni_web_con_python_amazon_ec2_")

    id = utils.generate_id(accent_folding.accent_fold, "Cloud Testing di applicazioni web con Python ed Amazon EC2 ed")
    assert _s.startsWith(id, "cloud_testing_applicazioni_web_con_python_amazon_ec2_")

    id = utils.generate_id(accent_folding.accent_fold, "di Cloud Testing di applicazioni web con Python ed Amazon EC2 ed")
    assert _s.startsWith(id, "cloud_testing_applicazioni_web_con_python_amazon_ec2_")

    id = utils.generate_id(accent_folding.accent_fold, "Startup in action: Frēstyl")
    assert _s.startsWith(id, "startup_action_frestyl_")

    id = utils.generate_id(accent_folding.accent_fold, "Raspberry Pi: un Ponte tra IT e Embedded")
    assert _s.startsWith(id, "raspberry_ponte_tra_embedded_")

    id = utils.generate_id(accent_folding.accent_fold, "テスト:")
    assert _s.startsWith(id, "テスト_")

  it "should ignore empty titles", () ->
    id = utils.generate_id(accent_folding.accent_fold)
    assert id.length is 5
    id = utils.generate_id(accent_folding.accent_fold, "")
    assert id.length is 5

  it "should parse float and round", () ->
    assert.equal 8.12, utils.my_parse_float("8.1234")
    assert.equal 8.123, utils.my_parse_float("8.1234", 1000)
    assert.equal 8.12, utils.my_parse_float(8.1234)
