const parse = require("./syntax").parse;
const morph = require("./morph");
const Store = morph.Store;

class SCC {
	constructor(text) {
		try {
			this.morphism = parse(text, {
				morphism: morph
			});
		} catch (e) {
			console.log(e);
			throw e;
		}
	}
	select(selector) {
		let store = new Store({}, new morph.IdentityLens(), selector, new morph.IdentityLens());
		return store.ap(this.morphism).get();
	}
}

module.exports = SCC;
