// lenses
class Lens {
	constructor(target) {
		this.target = target;
		this.tags = {};
	}
	focus(key) { return new FocusedLens(this, key) }
	lift(key, m) { f(this.focus(key)); return this }
	ap(m) { m(this); return this }
	get() { return this.target }
	tag(k, v) { this.tags[k] = v; return this }
}

class FocusedLens extends Lens {
	constructor(parent, key) {
		super(parent.target[key]);
		this.tags = parent.tags;
		this.parent = parent;
		this.key = key;
	}
	put(val) {
		this.target = this.parent.target[this.key] = val;
		return this;
	}
	cover(container) {
		if (!this.target) this.put(container)
		return this;
	}
}

// morphs
function put(x) { return l => l.put(x) }
function focus(k, m) { return l => m(l.focus(k)) }
function deepFocus(ks, m) {
	if (!ks.length) return m;
	if (ks.length === 1) return focus(ks[0], m);
	return l => l.focus(ks[0]).cover({}).ap(deepFocus(ks.slice(1), m))
}
function join(morphs) {
	return function (lens) {
		for (let morph of morphs) morph(lens);
	}
}
function fresh(morph) {
	return function (lens) {
		let l1 = new Lens({}).focus('<>');
		l1.tags = lens.tags;
		lens.put(l1.ap(morph).get())
	}
}
function biop(b) {
	return morph => lens => lens.put(b(lens.get(), new Lens({}).focus('<>').ap(morph).get()))
}
const id = m => m;
const opmap = {
	'=': id,
	':': id,
	'<-': id,
	':=': fresh,
	'+=': biop((x, y) => x + y),
	'-=': biop((x, y) => x - y),
	'*=': biop((x, y) => x * y),
	'/=': biop((x, y) => x / y),
	'%=': biop((x, y) => x % y)
}

module.exports = {
	Lens: Lens,
	put: put,
	focus: focus,
	deepFocus: deepFocus,
	join: join,
	fresh: fresh,
	opmap: opmap
}