const assert = require("assert");
const SCC = require("./main");

describe("SCC", function() {
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
  if enable-alpha ( alpha.enabled = true )
  if enable-beta  ( beta.enabled  = true )
  if enable-alpha if enable-beta ( both = true )
}

if family > {
  if a familyval = 1
  if b familyval = 2
  if(a = 1) yes = 1
  reflectA = $a
}

.($reflectSet) = 'reflect set'

obj = {
  for(segment : ["a"; "b"; "c"; "d"]) .($segment) = $segment
}

`);

	it("should be able to parse", () => assert.equal(config.select({}).title, "SCC Example"));
	it("should be able to handle selectors", () =>
		assert.equal(config.select({ "enable-alpha": true }).servers.alpha.enabled, true));
	it("should be able to handle conjunction selectors", () =>
		assert.equal(
			config.select({ "enable-alpha": true, "enable-beta": true }).servers.both,
			true
		));
	it("should be able to handle navigation selectors", () =>
		assert.equal(config.select({ family: { a: true } }).familyval, 1));
	it("should be able to handle equal selectors", () =>
		assert.equal(config.select({ family: { a: 1 } }).yes, 1));
	it("should be able to handle reflects", () =>
		assert.equal(config.select({ family: { a: 1000 } }).reflectA, 1000));
	it("should be able to handle reflects", () =>
		assert.equal(config.select({ reflectSet: "key" }).key, "reflect set"));
	it("should be able to handle loops", () =>
		assert.deepEqual(config.select({}).obj, { a: "a", b: "b", c: "c", d: "d" }));
});
