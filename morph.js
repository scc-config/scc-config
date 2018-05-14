"use strict";

const parse = require("./syntax").parse;
const fs = require("fs");
const path = require("path");

// lenses
class Lens {
	constructor(getter, setter) {
		this.get = getter;
		this.put = setter;
	}
	focus(key) {
		return new CompositeLens(this, new KeyLens(key));
	}
}

class IdentityLens extends Lens {
	constructor() {
		super(
			v => v,
			(v, x) => {
				throw new Error("Cannot put.");
			}
		);
	}
}

class KeyLens extends Lens {
	constructor(key) {
		super(v => v[key], (v, x) => (v[key] = x));
	}
}

class CompositeLens extends Lens {
	constructor(larger, smaller) {
		super(v => smaller.get(larger.get(v)), (v, x) => smaller.put(larger.get(v), x));
	}
}

// store
class Store {
	constructor(target, lens, cotarget, colens) {
		this.target = target;
		this.lens = lens;

		this.cotarget = cotarget;
		this.colens = colens;
	}
	focus(vLens) {
		return new Store(this.target, vLens(this.lens), this.cotarget, this.colens);
	}
	cofocus(vLens) {
		return new Store(this.target, this.lens, this.cotarget, vLens(this.colens));
	}
	fresh() {
		return new Store({}, new KeyLens("<>"), this.cotarget, this.colens);
	}
	ap(m) {
		m(this);
		return this;
	}
	get() {
		return this.lens.get(this.target);
	}
	put(v) {
		this.lens.put(this.target, v);
		return this;
	}
	pad(container) {
		if (!this.get()) this.put(container);
		return this;
	}
	coget() {
		return this.colens.get(this.cotarget);
	}
	coput(v) {
		this.colens.put(this.cotarget, v);
		return this;
	}
}

// morphs
function put(x) {
	return s => s.put(x);
}
function focus(k, m) {
	if (typeof k === "string") return s => m(s.focus(l => l.focus(k)));
	else
		return s => {
			const key = k.call(s, s);
			return m(s.focus(l => l.focus(key)));
		};
}
function deepFocus(ks, m) {
	if (!ks.length) return m;
	if (ks.length === 1) return focus(ks[0], m);
	const head = ks[0];
	if (typeof head === "string") {
		return s =>
			s
				.focus(l => l.focus(head))
				.pad({})
				.ap(deepFocus(ks.slice(1), m));
	} else {
		return s => {
			const key = head.call(s, s);
			return s
				.focus(l => l.focus(key))
				.pad({})
				.ap(deepFocus(ks.slice(1), m));
		};
	}
}
function join(morphs) {
	return function(store) {
		for (let morph of morphs) store.ap(morph);
	};
}
function fresh(morph) {
	return function(store) {
		store.put(
			store
				.fresh()
				.ap(morph)
				.get()
		);
	};
}
function biop(b) {
	return morph => store =>
		store.put(
			b(
				store.get(),
				store
					.fresh()
					.ap(morph)
					.get()
			)
		);
}
const id = m => m;
const opmap = {
	":": id,
	"<-": id,
	"=": fresh,
	":=": fresh,
	"++=": biop((x, y) => x.concat(y)),
	"+=": biop((x, y) => x + y),
	"-=": biop((x, y) => x - y),
	"*=": biop((x, y) => x * y),
	"/=": biop((x, y) => x / y),
	"%=": biop((x, y) => x % y)
};

const pbinop = f => (a, b) => store =>
	store.put(
		f(
			store
				.fresh()
				.ap(a)
				.get(),
			store
				.fresh()
				.ap(b)
				.get()
		)
	);
const puniop = f => a => store =>
	store.put(
		f(
			store
				.fresh()
				.ap(a)
				.get()
		)
	);
const combineMorph = (a, b) => store => store.ap(a).ap(b);
const popmap = {
	"==": pbinop((a, b) => a === b),
	"=/=": pbinop((a, b) => a !== b),
	"<": pbinop((a, b) => a < b),
	">": pbinop((a, b) => a > b),
	"<=": pbinop((a, b) => a <= b),
	">=": pbinop((a, b) => a >= b),
	"<<@": pbinop((a, b) => b.indexOf(a) >= 0),
	"/\\": pbinop((a, b) => a && b),
	"\\/": pbinop((a, b) => a || b),
	"+": pbinop((a, b) => a + b),
	"-": pbinop((a, b) => a - b),
	"*": pbinop((a, b) => a * b),
	"/": pbinop((a, b) => a / b),
	"<>": pbinop((a, b) => a[b]),
	"++": pbinop((a, b) => [...a, ...b]),
	"uni!": puniop(a => !a),
	"uni-": puniop(a => -a),

	// Special
	":+:": combineMorph
};

const includeCache = new Map();

const include = m => store => {
	const refpath = store.coget().$PATH;
	const newpath = path.resolve(
		path.dirname(refpath),
		store
			.fresh()
			.ap(m)
			.get()
	);
	let content = "";
	if (includeCache.has(newpath)) {
		content = includeCache.get(newpath);
	} else {
		content = fs.readFileSync(newpath, "utf-8");
		includeCache.set(newpath, content);
	}
	const mm = parse(content, { morphism: module.exports });

	store.coget().$PATH = newpath;
	store.ap(mm);
	store.coget().$PATH = refpath;
};

module.exports = {
	Lens: Lens,
	Store: Store,
	IdentityLens: IdentityLens,
	put: put,
	focus: focus,
	deepFocus: deepFocus,
	join: join,
	fresh: fresh,
	opmap: opmap,
	popmap: popmap,
	include
};
