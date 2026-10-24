/// Locks [s] left-to-right inside right-to-left text (Arabic / Sorani).
/// Without it, numbers and Latin units get reordered by the bidi algorithm
/// ("pcs 100" instead of "100 pcs", "pcs / $1000" instead of "$1000 / pcs").
/// Wraps the text in Unicode LTR isolate marks, so it keeps its own order
/// and the surrounding paragraph's alignment.
String ltr(String s) => '$_lri$s$_pdi';

// Built from code points rather than written into a string literal so the
// analyzer's bidi-characters-in-source check stays quiet.
final String _lri = String.fromCharCode(0x2066); // LEFT-TO-RIGHT ISOLATE
final String _pdi = String.fromCharCode(0x2069); // POP DIRECTIONAL ISOLATE
