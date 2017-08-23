# scc-config
Simply cascade configuration.

### Definition

```scc
# This is a SCC document.

title : "SCC Example"

owner : {
  name : "Belleve Invis"
  mail : "belleve@typeof.net"
}

database : {
  server : "192.168.1.1"
  ports : [8001; 8002]
  connection_max : 5000
  enabled : true
}

servers : {
  alpha : { ip : "10.0.0.1"; dc : "eqdc10" }
  beta  : { ip : "10.0.0.1"; dc : "eqdc10" }
  if enable-alpha ( alpha.enabled = true )
  if enable-beta  ( beta.enabled  = true )
}
```

## Spec

* SCC is case sensitive.
* A SCC file must be a valie UTF-8 encoded Unicode document.
* Whitespace means tab (0x09) or space (0x20).
* Newline means LF (0x0A) or CRLF (0x0D0A).

### Comment

A hash symbol marks the rest of the line as a comment.

```scc
# This is a full-line comment
key : "value" # This is a comment at the end of a line
```
### Assignments

SCC uses assignments to build the document. An assignment is a **key** corresponded with a **value** (or a *Morph*, more precisely). Assignments look like this:

```scc
key : "value"
```

Keys are dot-separated sequence of identifiers,  letters, numbers, underscores, and dashes (`A-Za-z0-9_-`), or strings for complex situations. This reveals that you can directly set the deep part of a nested object:

```scc
servers.alpha.enabled : true
```

### Values

### Selectors

You can prefix any assignment with a **selector**.

##Advanced

### Morphs

The key idea of SCC is called Morph, i.e., manipulation of the configuration object. A primitive value (numbers, strings and booleans) means replace the current target into it:

```scc
1
```

will result `1`.

Morphs can be **focused** given a field name and a colon. When one morph is focused, this morph is applied to the current target's given field:

```scc
a : 1
b : 2
```

will result in `{a:1, b:2}`. Our configuration is initially an empty object `{}`.

We can group morphs together using `{}`, which means ensuring the target is an object. The following SCC:

```
a : {
    x : 1
    y : 2
}
```

means that:

1. field `a` should be an object.
2. field `a.x` should be set to `1`.
3. field `a.y` should be set to `2`.

You can merge field assignments by simply combining them:

```scc
a : {
    x : 1
    y : 2
}
a : {
    x : 3
    z : 1
}
```

will result in `{x:3, y:2, z:1}`.