<?php
/* The Computer Language Benchmarks Game
   http://benchmarksgame.alioth.debian.org/
   
   contributed by Isaac Gouy, transliterated from Mike Pall's Lua program 
   further optimization by Oleksii Prudkyi
*/

function run_iter($n) {
    echo 'function run_iter($n) {', "\n";
    //$n = (int)$argv[1];
    $s = range(0, $n - 1);
    $i = $maxflips = $checksum = 0; 
    $sign = 1; 
    $m = $n - 1;
    $p = $q = $s;
    do {
       echo 'do {', "\n";
       // Copy and flip.
       $q0 = $p[0];
       if ($q0 != 0){
          echo 'if ($q0 != 0){', "\n";
          $q = $p;
          $flips = 1;
          do { 
             echo 'do { ', "\n";
             $qq = $q[$q0]; 
             if ($qq == 0){
                echo 'if ($qq == 0){', "\n";
                $checksum += $sign*$flips;
                if ($flips > $maxflips) {
                    echo 'if ($flips > $maxflips) {', "\n";
                    $maxflips = $flips;
                }
                break; 
             } 
             $q[$q0] = $q0; 
             if ($q0 >= 3){
                echo 'if ($q0 >= 3){', "\n";
                $i = 1; $j = $q0 - 1;
                do { 
                   echo 'do { ', "\n";
                   $t = $q[$i]; 
                   $q[$i] = $q[$j]; 
                   $q[$j] = $t; 
                   ++$i;
                   --$j;
                } while ($i < $j); 
             }
             $q0 = $qq; 
             ++$flips;
          } while (true); 
       }
       // Permute.
       if ($sign == 1){
          echo 'if ($sign == 1){', "\n";
          $t = $p[1]; $p[1] = $p[0]; $p[0] = $t; $sign = -1; // Rotate 0<-1.
       } else { 
          echo '} else { ', "\n";
          $t = $p[1]; $p[1] = $p[2]; $p[2] = $t; $sign = 1;  // Rotate 1<-2.
          for($i=2; $i<$n; ){ 
             echo 'for($i=2; $i<$n; ){ ', "\n";
             $sx = &$s[$i];
             if ($sx != 0) {
                echo 'if ($sx != 0) {', "\n";
                --$sx; 
                break; 
             }
             if ($i == $m){
                echo 'if ($i == $m){', "\n";
                //printf("%d\nPfannkuchen(%d) = %d\n", $checksum, $n, $maxflips);// Out of permutations.
                return;
             }
             $s[$i] = $i;
             // Rotate 0<-...<-i+1.
             $t = $p[0]; 
             for($j=0; $j<=$i; ){
                 echo 'for($j=0; $j<=$i; ){', "\n";
                 $p[$j++] = $p[$j];
             } 
             ++$i;
             $p[$i] = $t;
          }
       }
    } while (true);
}
?>
