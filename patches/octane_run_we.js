load('base.js');
load('richards.js');
load('deltablue.js');
load('crypto.js');
load('raytrace.js');
load('earley-boyer.js');
load('regexp.js');
load('splay.js');
load('navier-stokes.js');
load('pdfjs.js');
//load('mandreel.js');
//load('gbemu-part1.js');
//load('gbemu-part2.js');
//load('code-load.js');
//load('box2d.js');
//load('zlib.js');
//load('zlib-data.js');
load('typescript.js');
load('typescript-input.js');
load('typescript-compiler.js');


function main() {
  var suites = BenchmarkSuite.suites;
  for (var i = 0; i < suites.length; i++) {
    var suite = suites[i];
    var benchmarks = suite.benchmarks;
    for (var j = 0; j < benchmarks.length; j++) {
      var benchmark = benchmarks[j];
      print(benchmark.name);
      for (var k = 0; k < 2000; k++) {
        BenchmarkSuite.ResetRNG();
        benchmark.Setup();
        var start = performance.now();
        // Octane benchmarks consist of a (generally fast) "inner" iteration;
        // each benchmark then says "running me for
        // benchmark.deterministicIterations times makes for an outer
        // iteration". We only care about the outer iterations.
        for (var l = 0; l < benchmark.deterministicIterations; l++) {
          benchmark.run();
        }
        var elapsed = performance.now() - start;
        print('  ' + elapsed);
        benchmark.TearDown();
      }
    }
  }
}


main();
