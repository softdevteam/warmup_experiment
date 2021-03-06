# The Computer Language Benchmarks Game
# http://shootout.alioth.debian.org/
# Contributed by Sokolov Yura
# Modified by Rick Branson
# Modified by YAGUCHI Yuya

INITIAL_STATE = 42.0
$last = INITIAL_STATE

GR_IM = 139968.0
GR_IA = 3877.0
GR_IC = 29573.0

@alu =
   "GGCCGGGCGCGGTGGCTCACGCCTGTAATCCCAGCACTTTGG"+
   "GAGGCCGAGGCGGGCGGATCACCTGAGGTCAGGAGTTCGAGA"+
   "CCAGCCTGGCCAACATGGTGAAACCCCGTCTCTACTAAAAAT"+
   "ACAAAAATTAGCCGGGCGTGGTGGCGCGCGCCTGTAATCCCA"+
   "GCTACTCGGGAGGCTGAGGCAGGAGAATCGCTTGAACCCGGG"+
   "AGGCGGAGGTTGCAGTGAGCCGAGATCGCGCCACTGCACTCC"+
   "AGCCTGGGCGACAGAGCGAGACTCCGTCTCAAAAA"

@iub = [
    ["a", 0.27],
    ["c", 0.12],
    ["g", 0.12],
    ["t", 0.27],

    ["B", 0.02],
    ["D", 0.02],
    ["H", 0.02],
    ["K", 0.02],
    ["M", 0.02],
    ["N", 0.02],
    ["R", 0.02],
    ["S", 0.02],
    ["V", 0.02],
    ["W", 0.02],
    ["Y", 0.02],
]

@homosapiens = [
    ["a", 0.3029549426680],
    ["c", 0.1979883004921],
    ["g", 0.1975473066391],
    ["t", 0.3015094502008],
]

def make_repeat_fasta(src, n)
    puts "def make_repeat_fasta(src, n)"
    v = nil
    width = 60
    l = src.length
    s = src * ((n / l) + 1)
    s.slice!(n, l)
    #puts (s.scan(/.{1,#{width}}/).join("\n"))
    s.scan(/.{1,#{width}}/).join("\n")
end

def make_random_fasta(table, n)
    puts "def make_random_fasta(table, n)"
    rand = nil
    width = 60
    chunk = 1 * width
    prob = 0.0
    rwidth = (1..width)
    table = table.collect{|v|
        puts "table.collect{|v|"
        prob += v[1]
        [v[0], prob]
    }

    collector = "rand = ($last = ($last * GR_IA + GR_IC) % GR_IM) / GR_IM\n"
    table.each do |va, vb|
      puts "table.each do |va, vb|"
      collector += "next #{va.inspect} if #{vb.inspect} > rand\n"
    end

    # Looks like eval can't deal with comments inside
    #eval <<-EOF
    #  (1..(n/width)).each do |i|
    #    puts rwidth.collect{#{collector}}.join
    #  end
    #  if n%width != 0
    #    puts (1..(n%width)).collect{#{collector}}.join
    #  end
    #EOF
    eval <<-EOF
      (1..(n/width)).each do |i|
        puts "(1..(n/width)).each do |i|"
        rwidth.collect{#{collector}}.join
      end
      if n%width != 0
        puts "if n%width != 0"
        (1..(n%width)).collect{#{collector}}.join
      end
    EOF
end

def run_iter(n)
    $last = INITIAL_STATE
    puts "def run_iter(n)"
    #n = (ARGV[0] or 27).to_i

    #puts ">ONE Homo sapiens alu"
    make_repeat_fasta(@alu, n*2)

    #puts ">TWO IUB ambiguity codes"
    make_random_fasta(@iub, n*3)

    #puts ">THREE Homo sapiens frequency"
    make_random_fasta(@homosapiens, n*5)
end
