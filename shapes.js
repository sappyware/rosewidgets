.pragma library

var N = 180;
var PI = Math.PI;
var T = {
  circle:    { n: 2 },
  squircle:  { n: 5 },
  cookie4:   { lobes: 4, amp: 0.10 },
  cookie6:   { lobes: 6, amp: 0.085 },
  cookie7:   { lobes: 7, amp: 0.08 },
  cookie:    { lobes: 9, amp: 0.07 },
  sunny:     { lobes: 12, amp: 0.10 },
  flower:    { lobes: 8, amp: 0.14 },
  clover:    { lobes: 4, amp: 0.20 },
  scallop:   { lobes: 14, amp: 0.055, p: 0.55 },
  puffy:     { lobes: 5, amp: 0.12, p: 0.6 },
  pebble:    { lobes: 3, amp: 0.09 },
  triangle:  { sides: 3, rot: -PI / 2, smooth: 16 },
  diamond:   { sides: 4, rot: -PI / 2, smooth: 9 },
  pentagon:  { sides: 5, rot: -PI / 2, smooth: 8 },
  hexagon:   { sides: 6, rot: -PI / 2, smooth: 7 }
};
var cache = {};

function has(k) { return T[k] !== undefined; }
function names() { return Object.keys(T); }

function radii(k) {
  if (cache[k]) return cache[k];
  var p = T[k], out = [], i, t, r;
  for (i = 0; i < N; i++) {
    t = 2 * PI * i / N;
    if (p.n) {
      var cc = Math.abs(Math.cos(t)), ss = Math.abs(Math.sin(t));
      r = 1 / Math.pow(Math.pow(cc, p.n) + Math.pow(ss, p.n), 1 / p.n);
    } else if (p.sides) {
      var seg = 2 * PI / p.sides, a = (((t - p.rot) % seg) + seg) % seg - seg / 2;
      r = Math.cos(PI / p.sides) / Math.cos(a);
    } else {
      var c = Math.cos(p.lobes * (t - (p.rot || 0)));
      if (p.p) c = (c < 0 ? -1 : 1) * Math.pow(Math.abs(c), p.p);
      r = (1 + p.amp * c) / (1 + p.amp);
    }
    out.push(r);
  }
  if (p.smooth) {
    var sm = [], s = p.smooth, j;
    for (i = 0; i < N; i++) {
      var acc = 0;
      for (j = -s; j <= s; j++) acc += out[(i + j + N) % N];
      sm.push(acc / (2 * s + 1));
    }
    out = sm;
  }
  if (!p.n) {
    var mx = Math.max.apply(null, out);
    out = out.map(function (v) { return v / mx; });
  }
  out.push(out[0]);
  cache[k] = out;
  return out;
}

function lerp(a, b, t) {
  var o = [];
  for (var i = 0; i < b.length; i++) o.push(a[i] + (b[i] - a[i]) * t);
  return o;
}
