// The Computer Language Benchmarks Game
// http://benchmarksgame.alioth.debian.org/
//
//  Contributed by Ian Osgood

var INITIAL_STATE = 42;
var last = INITIAL_STATE, A = 3877, C = 29573, M = 139968;
var MOD = Math.pow(2, 32);

function rand(max) {
  last = (last * A + C) % M;
  return max * last / M;
}

var ALU =
  "GGCCGGGCGCGGTGGCTCACGCCTGTAATCCCAGCACTTTGG" +
  "GAGGCCGAGGCGGGCGGATCACCTGAGGTCAGGAGTTCGAGA" +
  "CCAGCCTGGCCAACATGGTGAAACCCCGTCTCTACTAAAAAT" +
  "ACAAAAATTAGCCGGGCGTGGTGGCGCGCGCCTGTAATCCCA" +
  "GCTACTCGGGAGGCTGAGGCAGGAGAATCGCTTGAACCCGGG" +
  "AGGCGGAGGTTGCAGTGAGCCGAGATCGCGCCACTGCACTCC" +
  "AGCCTGGGCGACAGAGCGAGACTCCGTCTCAAAAA";

function IUB() {
  return {
    a:0.27, c:0.12, g:0.12, t:0.27,
    B:0.02, D:0.02, H:0.02, K:0.02,
    M:0.02, N:0.02, R:0.02, S:0.02,
    V:0.02, W:0.02, Y:0.02
  }
}

function HomoSap() {
  return {
    a: 0.3029549426680,
    c: 0.1979883004921,
    g: 0.1975473066391,
    t: 0.3015094502008
  }
}

var DEBUG = false;

function wrap_print(s) {
  var i;
  for (i=0; i<s.length; i++) {
    checksum += s.charCodeAt(i);
  }
  checksum += 10; // newline ascii code
  checksum = checksum % MOD;

  if (DEBUG) {
    print(s);
  }
}

function makeCumulative(table) {
  var last = null;
  for (var c in table) {
    if (last) table[c] += table[last];
    last = c;
  }
}

function fastaRepeat(n, seq) {
  var seqi = 0, lenOut = 60;
  while (n>0) {
    if (n<lenOut) lenOut = n;
    if (seqi + lenOut < seq.length) {
      wrap_print( seq.substring(seqi, seqi+lenOut) );
      seqi += lenOut;
    } else {
      var s = seq.substring(seqi);
      seqi = lenOut - s.length;
      wrap_print( s + seq.substring(0, seqi) );
    }
    n -= lenOut;
  }
}

function fastaRandom(n, table) {
  var line = new Array(60);
  makeCumulative(table);
  while (n>0) {
    if (n<line.length) line = new Array(n);
    for (var i=0; i<line.length; i++) {
      var r = rand(1);
      for (var c in table) {
        if (r < table[c]) {
          line[i] = c;
          break;
        }
      }
    }
    wrap_print( line.join('') );
    n -= line.length;
  }
}

var SCALE = 10000;
var EXPECT_CKSUM = 9611973;
var checksum = 0;

function run_iter(n) {
  var i;
  for (i=0; i<n; i++) {

    fastaRepeat(2*SCALE, ALU)
    fastaRandom(3*SCALE, IUB())
    fastaRandom(5*SCALE, HomoSap())

    if (checksum != EXPECT_CKSUM) {
      print("bad checksum: " + checksum + " vs " + EXPECT_CKSUM);
      quit(1);
    }

    checksum = 0;
    last = INITIAL_STATE;
  }
}
