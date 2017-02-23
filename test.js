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
}`)

	it("should be able to parse", () => assert.equal(config.select().title, "SCC Example"));
	it("should be able to handle selectors", () => assert.equal(config.select(['enable-alpha']).servers.alpha.enabled, true));
})