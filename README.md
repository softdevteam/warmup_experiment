# SoftDev Warmup Experiment

This is the main repository for the Software Development Team Warmup Experiment
as detailed in the paper "Virtual Machine Warmup Blows Hot and Cold", by Edd
Barrett, Carl Friedrich Bolz, Rebecca Killick, Vincent Knight, Sarah Mount and
Laurence Tratt.

The paper is available [here](http://arxiv.org/abs/1602.00602)


## Usage

The script `build.sh` will fetch and build the VMs and the Krun benchmarking
system. Once the VMs are built the `Makefile` contains a target
`bench-with-reboots` which will run the experiment in full, however, you should
consult the Krun documentation (fetched into `krun/` by `build.sh`), as there
is a great deal of manual intervention needed to compile a tickless kernel,
disable Intel P-states, set up `rc.local` etc.

## Print-traced Benchmarks

The paper mentions that to ensure benchmarks are "AST deterministic",  we
instrumented them with print statements. These versions can be found alongside
the "proper" benchmarks under the `benchmarks/` directory.

For example under `benchmarks/fasta/lua/`:

 * `bench.lua` is the un-instrumented benchmark used in the proper experiment.
 * `trace_bench.lua` is the instrumented version.

Special notes:

 * Java benchmarks have and additional `trace_KrunEntry.java` file as well.
 * Since we cannot distribute Java Richards, a patch is required to derive the
   tracing version (`patches/trace_java_richards.diff`)

## License Information

<pre>
All original files are under the following MIT license:

  Copyright (c) 2015-2016 King's College London

  Permission is hereby granted, free of charge, to any person obtaining a
  copy of this software and associated documentation files (the "Software"),
  to deal in the Software without restriction, including without limitation
  the rights to use, copy, modify, merge, publish, distribute, sublicense,
  and/or sell copies of the Software, and to permit persons to whom the
  Software is furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
  DEALINGS IN THE SOFTWARE.

Files from the Computer Language Benchmarks Game are under a revised BSD
license:

  http://shootout.alioth.debian.org/license.php

The Richards benchmark is in the public domain (Martin Richards confirmed
"everything in my bench distribution is in the public domain except for the
directory sunjava.").

The LUA Richards benchmark is in the public domain:

  http://www.dcc.ufrj.br/~fabiom/richards_lua.zip

The Java Richards benchmark license is at:
  http://web.archive.org/web/20050825101121/http://www.sunlabs.com/people/mario/java_benchmarking/index.html
  (see also http://www.wolczko.com/java_benchmarking.html)
<pre>
