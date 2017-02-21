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

### Mandatory requirements

  * Python 2.7 - the code here is not Python 3.x ready
  * bzip2 / bunzip2
  * Python modules: numpy, rpy2
  * R
  * openssl and headers
  * pkg-config
  * curl and headers
  * gcc and make

### Optional requirements

  * PyPy (will allow some code here to run faster)
  * Python modules required for plotting: matplotlib, seaborn
  * Required for generating LaTeX tables: a LaTeX distribution which provides
    pdflatex, and the following packages: amsmath, amssymb, booktabs, calc,
    geometry, mathtools, multicol, multirow, rotating, sparklines, xspace.
    The TeX Live distribution should be fine.

### Installing on Debian systems

The following command will install all dependencies on Debian-based systems:

```sh
$ sudo apt-get install build-essential python2.7 pypy bzip2 r-base libssl-dev \
       pkg-config libcurl4-openssl-dev python-numpy python-rpy2 \
       python-matplotlib python-seaborn texlive texlive-latex-extra
```

### Setting up R

To run the scripts here, it is necessary to install some R packages. By default,
R will install these packages in `$HOME/R`. If you do not want R to use your
home directory, then set the environment variable `$R_LIBS_USER`, e.g. (in BASH):

```bash
$ git clone https://github.com/softdevteam/warmup_experiment.git
$ cd warmup_experiment
$ mkdir R
$ export R_LIBS_USER=`pwd`/R
$ echo "export R_LIBS_USER=`pwd`/R" >> ~/.bashrc
```

To install the necessary packages, open R on the command line, and run the
following commands:

```R
> install.packages("devtools")
```

At this point R may ask you to choose a CRAN mirror. Choose one and wait for
installation to complete.

Some Debian systems include a buggy version of R, as a work-around you may
have to execute this command:

```R
options(download.file.method = "wget")
```

Lastly, you need to run:

```R
> devtools::install_github("rkillick/changepoint")
```

### CSV format

The scripts here take CSV files as input. The format is as follows. The first row
must contain a header with a process execution id, benchmark name and sequence
of iteration numbers. Subsequent rows are data rows, one per process execution.
The in-process iteration index columns should contain the time in seconds for
the corresponding in-process iteration. Each process execution must execute the
same number of iterations as described in the header. For example:

```
    process_exec_num, bench_name, 0, 1, 2, ...
    0, spectral norm, 0.2, 0.1, 0.4, ...
    1, spectral norm, 0.3, 0.15, 0.2, ...
```

### Usage

The Python script `bin/warmup` must be used as a front-end to all other scripts.
The script can be used to generate JSON containing summary statistics for
the input data, PDF plots or LaTeX tables.

The script also needs the names of the language and VM under test, and the
output of `uname -a` on the machine the benchmarks were run on. Example usage:

```
./bin/warmup  --output-plots plots.pdf --output-json summary.json -l javascript -v V8 -u "`uname -a`" results.csv
```

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
