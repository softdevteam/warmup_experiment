<? 
/* The Computer Language Benchmarks Game
http://benchmarksgame.alioth.debian.org/

contributed by Isaac Gouy
modified by anon
*/

define("SPECTRAL_N", 1000);
define("EXPECT_CKSUM", 1.2742241481294835914184204739285632967948913574218750);


function A(&$i, &$j){
   return 1.0 / ( ( ( ($i+$j) * ($i+$j+1) ) >> 1 ) + $i + 1 );
}

function Av(&$n,&$v){
   global $_tpl;
   $Av = $_tpl;
   for ($i = 0; $i < $n; ++$i) {
      $sum = 0.0;
      foreach($v as $j=>$v_j) {
         $sum += A($i,$j) * $v_j;
      }
      $Av[$i] = $sum;
   }
   return $Av;
}

function Atv(&$n,&$v){
   global $_tpl;
   $Atv = $_tpl;
   for($i = 0; $i < $n; ++$i) {
      $sum = 0.0;
      foreach($v as $j=>$v_j) {
         $sum += A($j,$i) * $v_j;
      }
      $Atv[$i] = $sum;
   }
   return $Atv;
}

function AtAv(&$n,&$v){
   $tmp = Av($n,$v);
   return Atv($n, $tmp);
}

function run_iter($n) {
    for ($i = 0; $i < $n; $i++) {
        $checksum = inner_iter(SPECTRAL_N);
        if ($checksum != EXPECT_CKSUM) {
            echo "bad checksum: " . $checksum . " vs " . EXPECT_CKSUM . "\n";
            exit (1);
        }
    }
}

function inner_iter($n) {
  $u = array_fill(0, $n, 1.0);
  $_tpl = array_fill(0, $n, 0.0);

  for ($i=0; $i<10; $i++){
    $v = AtAv($n,$u);
    $u = AtAv($n,$v);
  }

  $vBv = 0.0;
  $vv = 0.0;
  $i = 0;
  foreach($v as $val) {
    $vBv += $u[$i]*$val;
    $vv += $val*$val;
    ++$i;
  }
  return sqrt($vBv/$vv);
}
?>
