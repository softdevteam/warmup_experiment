# The Computer Language Benchmarks Game
# http://shootout.alioth.debian.org/
#
# contributed by Antoine Pitrou
# modified by Dominique Wahli
# modified by Heinrich Acker

MIN_DEPTH = 4
MAX_DEPTH = 12
EXPECT_CKSUM = -10914

import sys

class Tree(object):
    __slots__ = ["item", "left", "right"] # for CPython
    def __init__(self, item, left, right):
        self.item = item
        self.left = left
        self.right = right

def make_tree(item, depth):
    if depth <= 0: return item
    item2 = item + item
    depth -= 1
    return Tree(item, make_tree(item2 - 1, depth), make_tree(item2, depth))

def check_tree(tree):
    if not isinstance(tree, Tree): return tree
    return tree.item + check_tree(tree.left) - check_tree(tree.right)


def inner_iter(min_depth, max_depth):
    checksum = 0
    stretch_depth = max_depth + 1

    checksum += check_tree(make_tree(0, stretch_depth))

    long_lived_tree = make_tree(0, max_depth)

    iterations = 2**max_depth
    for depth in xrange(min_depth, stretch_depth, 2):

        for i in xrange(1, iterations + 1):
            checksum += check_tree(make_tree(i, depth)) + check_tree(make_tree(-i, depth))

        iterations /= 4

    checksum += check_tree(long_lived_tree)

    if checksum != EXPECT_CKSUM:
        print("bad checksum: %d vs %d" % (checksum, EXPECT_CKSUM))
        sys.exit(1)


def run_iter(n):
    for i in xrange(n):
        inner_iter(MIN_DEPTH, MAX_DEPTH)
