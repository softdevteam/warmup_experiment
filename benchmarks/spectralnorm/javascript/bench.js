// The Computer Language Benchmarks Game
// http://benchmarksgame.alioth.debian.org/
//
// contributed by Ian Osgood
// Optimized by Roy Williams

var SPECTRAL_N  = 1000;
var EXPECT_CKSUM = 1.2742241481294835914184204739285632967948913574218750;

function A(i,j) {
  return 1/(((i+j)*(i+j+1)>>>1)+i+1);
}

function Au(u,v) {
    var n = u.length;
  for (var i=0; i<n; ++i) {
    var t = 0;
    for (var j=0; j<n; ++j)
      t += A(i,j) * u[j];
    v[i] = t;
  }
}

function Atu(u,v) {
  var n = u.length;
  for (var i=0; i<n; ++i) {
    var t = 0;
    for (var j=0; j<n; ++j)
      t += A(j,i) * u[j];
    v[i] = t;
  }
}

function AtAu(u,v,w) {
  Au(u,w);
  Atu(w,v);
}

function run_iter(n) {
  var i = 0;
  for (i = 0; i < n; i++) {
    var checksum = inner_iter(SPECTRAL_N);
    if (checksum != EXPECT_CKSUM) {
      print("bad checksum: " + checksum + " vs " + EXPECT_CKSUM);
    }
  }
}

function inner_iter(n) {
  var storage_ = new ArrayBuffer(n * 24);
  var u = new Float64Array(storage_, 0, n),
      v = new Float64Array(storage_, 8*n, n),
      w = new Float64Array(storage_, 16*n, n);
  var i, vv=0, vBv=0;
  for (i=0; i<n; ++i) {
    u[i] = 1; v[i] = w[i] = 0; 
  }
  for (i=0; i<10; ++i) {
    AtAu(u,v,w);
    AtAu(v,u,w);
  }
  for (i=0; i<n; ++i) {
    vBv += u[i]*v[i];
    vv  += v[i]*v[i];
  }
  return Math.sqrt(vBv/vv);
}

//print(spectralnorm(arguments[0]).toFixed(9));
