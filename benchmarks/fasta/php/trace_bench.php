<?php
/* The Computer Language Benchmarks Game
   http://benchmarksgame.alioth.debian.org/

   contributed by Wing-Chung Leung
   modified by Isaac Gouy
   modified by anon
 */

ob_implicit_flush(1);
ob_start(NULL, 4096);

$INITIAL_STATE = 42.0;
$last = $INITIAL_STATE;
function gen_random(&$last, &$randoms, $max = 1.0, $ia = 3877.0, $ic = 29573.0, $im = 139968.0) {
  echo 'function gen_random(&$last, &$randoms, $max = 1.0, $ia = 3877.0, $ic = 29573.0, $im = 139968.0) {', "\n";
   foreach($randoms as &$r) {
      echo 'foreach($randoms as &$r) {', "\n";
      $r = $max * ($last = ($last * $ia + $ic) % $im) / $im;
   }
}

/* Weighted selection from alphabet */

function makeCumulative(&$genelist) {
   echo 'function makeCumulative(&$genelist) {', "\n";
   $cumul = 0.0;
   foreach($genelist as $k=>&$v) {
      echo 'foreach($genelist as $k=>&$v) {', "\n";
      $cumul = $v += $cumul;
   }
}


/* Generate and write FASTA format */

function makeRandomFasta(&$genelist, $n) {
   echo 'function makeRandomFasta(&$genelist, $n) {', "\n";
   $width = 60;
   $lines = (int) ($n / $width);
   $pick = str_repeat('?', $width)."\n";
   $randoms = array_fill(0, $width, 0.0);
   global $last;

   // full lines
   for ($i = 0; $i < $lines; ++$i) {
      echo 'for ($i = 0; $i < $lines; ++$i) {', "\n";
      gen_random($last, $randoms);
      $j = 0;
      foreach ($randoms as $r) {
         echo 'foreach ($randoms as $r) {', "\n";
         foreach($genelist as $k=>$v) {
            echo 'foreach($genelist as $k=>$v) {', "\n";
            if ($r < $v) {
               echo 'if ($r < $v) {', "\n";
               break;
            }
         }
         $pick[$j++] = $k;
      }
      //echo $pick;
   }

   // last, partial line
   $w = $n % $width;
   if ($w !== 0) {
      echo 'if ($w !== 0) {', "\n";
      $randoms = array_fill(0, $w, 0.0);
      gen_random($last, $randoms);
      $j = 0;
      foreach ($randoms as $r) {
         echo 'foreach ($randoms as $r) {', "\n";
         foreach($genelist as $k=>$v) {
            echo 'foreach($genelist as $k=>$v) {', "\n";
            if ($r < $v) {
               echo 'if ($r < $v) {', "\n";
               break;
            }
         }
         $pick[$j++] = $k;
      }
      $pick[$w] = "\n";
   }

}


function makeRepeatFasta($s, $n) {
   echo 'function makeRepeatFasta($s, $n) {', "\n";
   $i = 0; $sLength = strlen($s); $lineLength = 60;
   while ($n > 0) {
      echo 'while ($n > 0) {', "\n";
      if ($n < $lineLength) {
         echo 'if ($n < $lineLength) {', "\n";
         $lineLength = $n;
      }
      if ($i + $lineLength < $sLength){
         echo 'if ($i + $lineLength < $sLength){', "\n";
         //print(substr($s,$i,$lineLength)); print("\n");
         $no_use = substr($s,$i,$lineLength);
         $i += $lineLength;
      } else {
         echo '} else {', "\n";
         //print(substr($s,$i));
         $no_use = substr($s,$i);
         $i = $lineLength - ($sLength - $i);
         //print(substr($s,0,$i)); print("\n");
         $no_use = substr($s,0,$i);
      }
      $n -= $lineLength;
   }
}


/* Main -- define alphabets, make 3 fragments */

$iub=array(
   'a' => 0.27,
   'c' => 0.12,
   'g' => 0.12,
   't' => 0.27,

   'B' => 0.02,
   'D' => 0.02,
   'H' => 0.02,
   'K' => 0.02,
   'M' => 0.02,
   'N' => 0.02,
   'R' => 0.02,
   'S' => 0.02,
   'V' => 0.02,
   'W' => 0.02,
   'Y' => 0.02
);

$homosapiens = array(
   'a' => 0.3029549426680,
   'c' => 0.1979883004921,
   'g' => 0.1975473066391,
   't' => 0.3015094502008
);

$alu =
   'GGCCGGGCGCGGTGGCTCACGCCTGTAATCCCAGCACTTTGG' .
   'GAGGCCGAGGCGGGCGGATCACCTGAGGTCAGGAGTTCGAGA' .
   'CCAGCCTGGCCAACATGGTGAAACCCCGTCTCTACTAAAAAT' .
   'ACAAAAATTAGCCGGGCGTGGTGGCGCGCGCCTGTAATCCCA' .
   'GCTACTCGGGAGGCTGAGGCAGGAGAATCGCTTGAACCCGGG' .
   'AGGCGGAGGTTGCAGTGAGCCGAGATCGCGCCACTGCACTCC' .
   'AGCCTGGGCGACAGAGCGAGACTCCGTCTCAAAAA';

makeCumulative($iub);
makeCumulative($homosapiens);

function run_iter($n) {
    echo 'function run_iter($n) {', "\n";
    //$n = 1000;
    global $iub, $homosapiens, $alu, $last, $INITIAL_STATE;
    $last = $INITIAL_STATE;

    //if ($_SERVER['argc'] > 1) $n = $_SERVER['argv'][1];

    //echo ">ONE Homo sapiens alu\n";
    makeRepeatFasta($alu, $n*2);

    //echo ">TWO IUB ambiguity codes\n";
    makeRandomFasta($iub, $n*3);

    //echo ">THREE Homo sapiens frequency\n";
    makeRandomFasta($homosapiens, $n*5);
}

?>
