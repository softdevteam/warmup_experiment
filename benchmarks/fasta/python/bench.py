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

CHECKSUM = 0;
SCALE = 10000
EXPECT_CKSUM = 9611973


def wrap_print(s):
    """Wrap stdout writes to generare checksum"""

    global CHECKSUM

    # newline would have been implicit in a print.
    for ch in s:
        CHECKSUM = (CHECKSUM + ord(ch))
    CHECKSUM += 10  # newline ascii code


def makeCumulative(table):
    P = []
    C = []
    prob = 0.
    for char, p in table:
        prob += p
        P += [prob]
        C += [char]
    return (P, C)

randomGenState = INITIAL_STATE
randomLUT = None
def makeRandomLUT():
    global randomLUT
    ia = 3877; ic = 29573
    randomLUT = array.array("i", [(s * ia + ic) % IM for s in xrange(IM)])

def makeLookupTable(table):
    bb = bisect.bisect
    probs, chars = makeCumulative(table)
    imf = float(IM)
    return array.array("c", [chars[bb(probs, i / imf)] for i in xrange(IM)])

def repeatFasta(src, n):
    width = 60
    r = len(src)
    s = src + src + src[:n % r]
    for j in xrange(n // width):
        i = j*width % r
        wrap_print(s[i:i+width])
    if n % width:
        wrap_print(s[-(n % width):])

def randomFasta(table, n):
    global randomLUT, randomGenState
    width = 60
    rgs = randomGenState
    rlut = randomLUT

    lut = makeLookupTable(table)
    line_buffer = []
    la = line_buffer.append

    for i in xrange(n // width):
        for i in xrange(width):
            rgs = rlut[rgs]
            la(lut[rgs])
        wrap_print(''.join(line_buffer))
        line_buffer[:] = []
    if n % width:
        for i in xrange(n % width):
            rgs = rlut[rgs]
            la(lut[rgs])
        wrap_print(''.join(line_buffer))

    randomGenState = rgs


def run_iter(n):
    global randomGenState, CHECKSUM

    for i in xrange(n):
        makeRandomLUT()

        repeatFasta(alu, SCALE * 2)
        randomFasta(iub, SCALE * 3)
        randomFasta(homosapiens, SCALE * 5)

        if CHECKSUM != EXPECT_CKSUM:
            print("Incorrect checksum: %s vs %s" % (CHECKSUM, EXPECT_CKSUM))
            sys.exit(1)

        randomGenState = INITIAL_STATE
        CHECKSUM = 0
