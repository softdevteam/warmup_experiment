# The Computer Language Benchmarks Game
# http://shootout.alioth.debian.org/
#
# modified by Ian Osgood
# modified again by Heinrich Acker
# modified by Justin Peel
# modified by Mariano Chouza
# modified by Ashley Hewson

import sys, bisect, array

alu = (
   'GGCCGGGCGCGGTGGCTCACGCCTGTAATCCCAGCACTTTGG'
   'GAGGCCGAGGCGGGCGGATCACCTGAGGTCAGGAGTTCGAGA'
   'CCAGCCTGGCCAACATGGTGAAACCCCGTCTCTACTAAAAAT'
   'ACAAAAATTAGCCGGGCGTGGTGGCGCGCGCCTGTAATCCCA'
   'GCTACTCGGGAGGCTGAGGCAGGAGAATCGCTTGAACCCGGG'
   'AGGCGGAGGTTGCAGTGAGCCGAGATCGCGCCACTGCACTCC'
   'AGCCTGGGCGACAGAGCGAGACTCCGTCTCAAAAA')

iub = zip('acgtBDHKMNRSVWY', [0.27, 0.12, 0.12, 0.27] + [0.02]*11)

homosapiens = [
    ('a', 0.3029549426680),
    ('c', 0.1979883004921),
    ('g', 0.1975473066391),
    ('t', 0.3015094502008),
]

IM = 139968
INITIAL_STATE = 42

def makeCumulative(table):
    print "def makeCumulative(table):"
    P = []
    C = []
    prob = 0.
    for char, p in table:
        print "for char, p in table:"
        prob += p
        P += [prob]
        C += [char]
    return (P, C)

randomGenState = INITIAL_STATE
randomLUT = None
def makeRandomLUT():
    print "def makeRandomLUT():"
    global randomLUT
    ia = 3877; ic = 29573
    randomLUT = array.array("i", [(s * ia + ic) % IM for s in xrange(IM)])

def makeLookupTable(table):
    print "def makeLookupTable(table):"
    bb = bisect.bisect
    probs, chars = makeCumulative(table)
    imf = float(IM)
    return array.array("c", [chars[bb(probs, i / imf)] for i in xrange(IM)])

def repeatFasta(src, n):
    print "def repeatFasta(src, n):"
    width = 60
    r = len(src)
    s = src + src + src[:n % r]
    for j in xrange(n // width):
        print "for j in xrange(n // width):"
        i = j*width % r
        #print s[i:i+width]
        s[i:i+width]
    if n % width:
        print "if n % width:"
        #print s[-(n % width):]
        s[-(n % width):]

def randomFasta(table, n):
    print "def randomFasta(table, n):"
    global randomLUT, randomGenState
    width = 60
    rgs = randomGenState
    rlut = randomLUT
    
    lut = makeLookupTable(table)
    line_buffer = []
    la = line_buffer.append
    
    for i in xrange(n // width):
        print "for i in xrange(n // width):"
        for i in xrange(width):
            print "for i in xrange(width):"
            rgs = rlut[rgs]
            la(lut[rgs])
        #print ''.join(line_buffer)
        ''.join(line_buffer)
        line_buffer[:] = []
    if n % width:
        print "if n % width:"
        for i in xrange(n % width):
            print "for i in xrange(n % width):"
            rgs = rlut[rgs]
            la(lut[rgs])
        #print ''.join(line_buffer)
        ''.join(line_buffer)
    
    randomGenState = rgs

def run_iter(n):
    print "def run_iter(n):"
    global randomGenState
    randomGenState = INITIAL_STATE
    #n = int(sys.argv[1])

    makeRandomLUT()

    #print '>ONE Homo sapiens alu'
    repeatFasta(alu, n*2)

    #print '>TWO IUB ambiguity codes'
    randomFasta(iub, n*3)

    #print '>THREE Homo sapiens frequency'
    randomFasta(homosapiens, n*5)
    
#main()
