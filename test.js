const assert = require('assert');
const SCC = require('./main');

describe("SCC", function () {

  let config = new SCC(`
# This is a SCC document.

title = "SCC Example"

owner = {
  name = "Belleve Invis"
  mail = "belleve@typeof.net"
}

database = {
  server = "192.168.1.1"
  ports = [8001; 8002]
  connection_max = 5000
  enabled = true
}

servers = {
  alpha = { ip = "10.0.0.1"; dc = "eqdc10" }
  beta  = { ip = "10.0.0.1"; dc = "eqdc10" }
  .enable-alpha ( alpha.enabled = true )
  .enable-beta  ( beta.enabled  = true )
  .enable-alpha.enable-beta ( both = true )
}

.family > { .a familyval = 1; .b familyval = 2 }
`)

  it("should be able to parse",
    () => assert.equal(config.select().title, "SCC Example"));
  it("should be able to handle selectors",
    () => assert.equal(config.select({ 'enable-alpha': true }).servers.alpha.enabled, true));
  it("should be able to handle conjunction selectors",
    () => assert.equal(config.select({ 'enable-alpha': true, 'enable-beta': true }).servers.both, true));
  it("should be able to handle navigation selectors",
    () => assert.equal(config.select({ family: { a: true } }).familyval, 1));
})