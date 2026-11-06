  .pragma library
function stripComment(s) {
  var q = null;
  for (var i = 0; i < s.length; i++) {
    var c = s[i];
    if (q) { if (c === "\\" && q === '"') i++; else if (c === q) q = null; }
    else if (c === '"' || c === "'") q = c;
    else if (c === "#") return s.slice(0, i);
  }
  return s;
}
function splitTop(s) {
  var out = [], q = null, depth = 0, cur = "";
  for (var i = 0; i < s.length; i++) {
    var c = s[i];
    if (q) { cur += c; if (c === "\\" && q === '"') cur += s[++i]; else if (c === q) q = null; continue; }
    if (c === '"' || c === "'") { q = c; cur += c; }
    else if (c === "[") { depth++; cur += c; }
    else if (c === "]") { depth--; cur += c; }
    else if (c === "," && depth === 0) { out.push(cur); cur = ""; }
    else cur += c;
  }
  if (cur.trim() !== "") out.push(cur);
  return out;
}
function value(v) {
  v = v.trim();
  if (v === "true") return true;
  if (v === "false") return false;
  if (v[0] === '"') return JSON.parse(v);
  if (v[0] === "'") return v.slice(1, -1);
  if (v[0] === "[") return splitTop(v.slice(1, -1)).map(value);
  var n = Number(v.replace(/_/g, ""));
  return isNaN(n) ? v : n;
}
function parse(text) {
  var root = {}, cur = root, lines = text.split(/\r?\n/);
  for (var i = 0; i < lines.length; i++) {
    var l = stripComment(lines[i]).trim();
    if (!l) continue;
    var h = l.match(/^\[([^\]]+)\]$/);
    if (h) {
      cur = root;
      h[1].split(".").forEach(function (k) { k = k.trim(); if (typeof cur[k] !== "object") cur[k] = {}; cur = cur[k]; });
      continue;
    }
    var eq = l.indexOf("=");
    if (eq < 0) continue;
    var key = l.slice(0, eq).trim().replace(/^"|"$/g, "");
    try { cur[key] = value(l.slice(eq + 1)); } catch (e) {}
  }
  return root;
}
function fmt(v) {
  if (Array.isArray(v)) return "[" + v.map(fmt).join(", ") + "]";
  return typeof v === "string" ? JSON.stringify(v) : String(v);
}
function setKeys(text, section, kv) {
  var lines = text.split("\n"), start = -1, end = lines.length;
  for (var i = 0; i < lines.length; i++) {
    var m = stripComment(lines[i]).trim().match(/^\[([^\]]+)\]$/);
    if (!m) continue;
    if (start >= 0) { end = i; break; }
    if (m[1].trim() === section) start = i;
  }
  if (start < 0) return text;
  for (var k in kv) {
    var re = new RegExp("^\\s*" + k + "\\s*="), found = false;
    for (var j = start + 1; j < end; j++)
      if (re.test(lines[j])) { lines[j] = k + " = " + fmt(kv[k]); found = true; break; }
    if (!found) { lines.splice(start + 1, 0, k + " = " + fmt(kv[k])); end++; }
  }
  return lines.join("\n");
}
function removeSection(text, section) {
  var lines = text.split("\n"), start = -1, end = lines.length;
  for (var i = 0; i < lines.length; i++) {
    var m = stripComment(lines[i]).trim().match(/^\[([^\]]+)\]$/);
    if (!m) continue;
    if (start >= 0) { end = i; break; }
    if (m[1].trim() === section) start = i;
  }
  if (start < 0) return text;
  lines.splice(start, end - start);
  return lines.join("\n").replace(/\n{3,}/g, "\n\n");
}
