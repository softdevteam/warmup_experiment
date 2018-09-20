# SoftDev Warmup Experiment

This is the main repository for the Software Development Team Warmup Experiment
as detailed in the paper "Virtual Machine Warmup Blows Hot and Cold", by Edd
Barrett, Carl Friedrich Bolz, Rebecca Killick, Sarah Mount and Laurence Tratt.

The paper is available [here](http://arxiv.org/abs/1602.00602)


## Running the warmup experiment

The script `build.sh` will fetch and build the VMs and the Krun benchmarking
system. Once the VMs are built the `Makefile` contains a target
`bench-with-reboots` which will run the experiment in full, however, you should
consult the Krun documentation (fetched into `krun/` by `build.sh`), as there
is a great deal of manual intervention needed to compile a tickless kernel,
disable Intel P-states, set up `rc.local` etc.

Note that the experiment is designed to run on amd64 machines running Debian 8
or OpenBSD. Newer versions of Debian do not currently work due to a C++ ABI
bump which would require a newer C++ compiler (a newer GCC or perhaps clang).

Calling `build.sh` will also install our
[warmup_stats](https://github.com/softdevteam/warmup_stats) code, which includes
a number of scripts to format benchmark results as plots or tables (similar to
those seen in the paper), and diff between results files. `warmup_stats` has a
number of dependencies, some of which are also needed by the code in this
repository, in particular:

  * Python 2.7 - the code here is not Python 3.x ready
  * bzip2 / bunzip2 and bzip2 (including header files)
  * curl (including header files)
  * gcc and make
  * liblzma library (including header files)
  * Python modules: numpy, pip, libcap
  * openssl (including header files)
  * pkg-config
  * pcre library (including header files)
  * readline (including header files)
  * wget

The [install instructions](https://github.com/softdevteam/warmup_stats/blob/master/INSTALL.md) for `warmup_stats` contain more details.


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

All original files are distributed under the UPL license.

Benchmarks from the Computer Language Benchmarks Game are under a revised BSD
license:

  http://shootout.alioth.debian.org/license.php

The Richards benchmark is in the public domain (Martin Richards confirmed
"everything in my bench distribution is in the public domain except for the
directory sunjava.").

The Lua Richards benchmark is in the public domain:

  http://www.dcc.ufrj.br/~fabiom/richards_lua.zip

The Java Richards benchmark is distributed under a license from Sun
Microsystems:

  http://web.archive.org/web/20050825101121/http://www.sunlabs.com/people/mario/java_benchmarking/index.html

(see also http://www.wolczko.com/java_benchmarking.html)
