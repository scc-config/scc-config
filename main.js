"use strict";

const parse = require("./syntax").parse;
const morph = require("./morph");
const Store = morph.Store;

class SCC {
	constructor(text, path) {
		try {
			this.morphism = parse(text, { morphism: morph });
			this.path = path || "";
		} catch (e) {
			console.log(e);
			throw e;
		}
	}
	select(selector) {
		let store = new Store(
			{},
			new morph.IdentityLens(),
			Object.assign({}, selector, { $PATH: this.path }),
			new morph.IdentityLens()
		);
		return store.ap(this.morphism).get();
	}
}

module.exports = SCC;
