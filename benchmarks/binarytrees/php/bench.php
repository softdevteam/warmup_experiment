<?php 
/* The Computer Language Benchmarks Game
   http://benchmarksgame.alioth.debian.org/

   contributed by Peter Baltruschat
   modified by Levi Cameron
   modified by Craig Russell
 */

define("MIN_DEPTH", 4);
define("MAX_DEPTH", 12);
define("EXPECT_CKSUM", -10914);

class Tree {
   public $i;
   public $l;
   public $r;
   
   public function __construct($item, $depth) {
      $this->i = $item;
      if($depth) {
         $this->l = new Tree($item * 2 - 1, --$depth);
         $this->r = new Tree($item * 2, $depth);
      }
   }
   
   public function check() {
      return $this->i
         + ($this->l->l === null ? $this->l->check() : $this->l->i)
         - ($this->r->l === null ? $this->r->check() : $this->r->i);
   }
}


function inner_iter($minDepth, $maxDepth) {
    $check = 0;
    $stretchDepth = $maxDepth + 1;

    $stretch = new Tree(0, $stretchDepth);
    $check += $stretch->check();
    unset($stretch);

    $longLivedTree = new Tree(0, $maxDepth);

    $iterations = 1 << $maxDepth;
    do
    {
       for($i = 1; $i <= $iterations; ++$i)
       {
          $check += (new Tree($i, $minDepth))->check()
             + (new Tree(-$i, $minDepth))->check();
       }

       $minDepth += 2;
       $iterations >>= 2;
    }
    while($minDepth <= $maxDepth);

    $check += $longLivedTree->check();

    if ($check != EXPECT_CKSUM) {
        echo "bad checksum: " . $check . " vs " . EXPECT_CKSUM . "\n";
        exit(1);
    }
}

function run_iter($n) {
    for ($i = 0; $i < $n; $i++) {
        inner_iter(MIN_DEPTH, MAX_DEPTH);
    }
}
?>
