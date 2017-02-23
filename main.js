const parse = require('./syntax').parse;
const morph = require('./morph');
const Lens = morph.Lens;

class SCC {
	constructor(text) {
		this.morphism = parse(text, {
			morphism: morph
		})
	}
	/**
	 * @param {Lens} lens
	 * @param {string} n
	 * @param {Array<Set<string>>} path
	 */
	select(...path) {
		const pp = ['*'].concat(path).map(s => new Set(s));
		let lens = new Lens({}).tag('path', pp).focus('<>').cover({});
		this.morphism(lens);
		return lens.get()
	}
}

module.exports = SCC;