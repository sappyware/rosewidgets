.pragma library

function cl(x, a, b) { return Math.max(a, Math.min(b, x)); }
function lin(c) { return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4); }
function gam(c) { c = cl(c, 0, 1); return c <= 0.0031308 ? 12.92 * c : 1.055 * Math.pow(c, 1 / 2.4) - 0.055; }

function parseHex(h) {
  h = String(h || "").replace("#", "");
  if (h.length === 3) h = h[0] + h[0] + h[1] + h[1] + h[2] + h[2];
  if (h.length === 8) h = h.slice(2);
  var n = parseInt(h, 16);
  if (h.length !== 6 || isNaN(n)) n = 0x6750A4;
  return [((n >> 16) & 255) / 255, ((n >> 8) & 255) / 255, (n & 255) / 255];
}
function p2(v) { var s = Math.round(cl(v, 0, 1) * 255).toString(16); return s.length < 2 ? "0" + s : s; }
function hexSrgb(r, g, b) { return "#" + p2(r) + p2(g) + p2(b); }
function hexLin(r, g, b) { return hexSrgb(gam(r), gam(g), gam(b)); }

function mix(a, b, t) {
  var x = parseHex(a), y = parseHex(b);
  return hexSrgb(x[0] + (y[0] - x[0]) * t, x[1] + (y[1] - x[1]) * t, x[2] + (y[2] - x[2]) * t);
}

function toLch(hex) {
  var c = parseHex(hex), r = lin(c[0]), g = lin(c[1]), b = lin(c[2]);
  var l = Math.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
  var m = Math.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
  var s = Math.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
  var L = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s;
  var A = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s;
  var B = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s;
  return { L: L, C: Math.sqrt(A * A + B * B), h: Math.atan2(B, A) };
}

function lchLin(L, C, h) {
  var A = C * Math.cos(h), B = C * Math.sin(h);
  var l = L + 0.3963377774 * A + 0.2158037573 * B;
  var m = L - 0.1055613458 * A - 0.0638541728 * B;
  var s = L - 0.0894841775 * A - 1.2914855480 * B;
  l = l * l * l; m = m * m * m; s = s * s * s;
  return [
    4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
    -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
    -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
  ];
}
function inGamut(c) {
  for (var i = 0; i < 3; i++) if (c[i] < -0.0002 || c[i] > 1.0002) return false;
  return true;
}
function fit(L, C, h) {
  if (inGamut(lchLin(L, C, h))) return C;
  var lo = 0, hi = C;
  for (var i = 0; i < 14; i++) {
    var mid = (lo + hi) / 2;
    if (inGamut(lchLin(L, mid, h))) lo = mid; else hi = mid;
  }
  return lo;
}
function lum(c) { return 0.2126 * cl(c[0], 0, 1) + 0.7152 * cl(c[1], 0, 1) + 0.0722 * cl(c[2], 0, 1); }
function toneY(t) { return t > 8 ? Math.pow((t + 16) / 116, 3) : t / 903.2963; }


function tone(h, C, t) {
  if (t <= 0) return "#000000";
  if (t >= 100) return "#ffffff";
  var Y = toneY(t), lo = 0, hi = 1, rgb;
  for (var i = 0; i < 24; i++) {
    var L = (lo + hi) / 2;
    rgb = lchLin(L, fit(L, C, h), h);
    if (lum(rgb) < Y) lo = L; else hi = L;
  }
  var Lf = (lo + hi) / 2;
  rgb = lchLin(Lf, fit(Lf, C, h), h);
  return hexLin(rgb[0], rgb[1], rgb[2]);
}
function pal(h, C) {
  var cache = {};
  return function (t) { return cache[t] !== undefined ? cache[t] : (cache[t] = tone(h, C, t)); };
}


function scheme(seed, dark) {
  var s = toLch(seed), h = s.h, c = cl(s.C, 0.10, 0.15);
  var P = pal(h, c), S = pal(h, c * 0.45), T = pal(h + Math.PI / 3, c * 0.7);
  var N = pal(h, 0.012), V = pal(h, 0.022), E = pal(0.47, 0.25);
  function r(a, b) { return dark ? b : a; }
  return {
    dark: dark, seed: seed,
    primary: P(r(40, 80)), onPrimary: P(r(100, 20)), primaryContainer: P(r(90, 30)), onPrimaryContainer: P(r(10, 90)),
    secondary: S(r(40, 80)), onSecondary: S(r(100, 20)), secondaryContainer: S(r(90, 30)), onSecondaryContainer: S(r(10, 90)),
    tertiary: T(r(40, 80)), onTertiary: T(r(100, 20)), tertiaryContainer: T(r(90, 30)), onTertiaryContainer: T(r(10, 90)),
    error: E(r(40, 80)), onError: E(r(100, 20)), errorContainer: E(r(90, 30)), onErrorContainer: E(r(10, 90)),
    surface: N(r(98, 6)), onSurface: N(r(10, 90)), surfaceVariant: V(r(90, 30)), onSurfaceVariant: V(r(30, 80)),
    surfaceDim: N(r(87, 6)), surfaceBright: N(r(98, 24)),
    surfaceContainerLowest: N(r(100, 4)), surfaceContainerLow: N(r(96, 10)), surfaceContainer: N(r(94, 12)),
    surfaceContainerHigh: N(r(92, 17)), surfaceContainerHighest: N(r(90, 22)),
    outline: V(r(50, 60)), outlineVariant: V(r(80, 30)),
    inverseSurface: N(r(20, 90)), inverseOnSurface: N(r(95, 20)), inversePrimary: P(r(80, 40))
  };
}
