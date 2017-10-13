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

## Using the scripts here to analyse an existing benchmark

In order to use the scripts here, a number of packages need to be installed.
The `build_stats.sh` script will install most of these, but for more detailed
instructions please see the INSTALL.md file.

### CSV format

The scripts here take CSV files as input. The format is as follows. The first row
must contain a header with a process execution id, benchmark name and sequence
of iteration numbers. Subsequent rows are data rows, one per process execution.
Each row should contain an index for the given process execution, the benchmark
name and a list of times in seconds for the corresponding in-process iteration.
Each process execution must execute the same number of iterations as described
in the header. For example:

```
    process_exec_num, bench_name, 0, 1, 2, ...
    0, spectral norm, 0.2, 0.1, 0.4, ...
    1, spectral norm, 0.3, 0.15, 0.2, ...
```

### Usage

The Python script `bin/warmup_stats` must be used as a front-end to all other scripts.
The script can be used to generate JSON containing summary statistics for
the input data, PDF plots or LaTeX tables.

The script also needs the names of the language and VM under test, and the
output of `uname -a` on the machine the benchmarks were run on. Example usage:

```
./bin/warmup_stats  --output-plots plots.pdf --output-json summary.json -l javascript -v V8 -u "`uname -a`" results.csv
```

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
