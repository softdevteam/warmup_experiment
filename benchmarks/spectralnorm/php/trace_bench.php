<? 
/* The Computer Language Benchmarks Game
http://benchmarksgame.alioth.debian.org/

contributed by Isaac Gouy
modified by anon
*/


function A(&$i, &$j){
   echo 'function A(&$i, &$j){', "\n";
   return 1.0 / ( ( ( ($i+$j) * ($i+$j+1) ) >> 1 ) + $i + 1 );
}

function Av(&$n,&$v){
   echo('function Av(&$n,&$v){');
   global $_tpl;
   $Av = $_tpl;
   for ($i = 0; $i < $n; ++$i) {
      echo 'for ($i = 0; $i < $n; ++$i) {', "\n";
      $sum = 0.0;
      foreach($v as $j=>$v_j) {
         echo 'foreach($v as $j=>$v_j) {', "\n";
         $sum += A($i,$j) * $v_j;
      }
      $Av[$i] = $sum;
   }
   return $Av;
}

function Atv(&$n,&$v){
   echo 'function Atv(&$n,&$v){', "\n";
   global $_tpl;
   $Atv = $_tpl;
   for($i = 0; $i < $n; ++$i) {
      echo 'for($i = 0; $i < $n; ++$i) {', "\n";
      $sum = 0.0;
      foreach($v as $j=>$v_j) {
         echo 'foreach($v as $j=>$v_j) {', "\n";
         $sum += A($j,$i) * $v_j;
      }
      $Atv[$i] = $sum;
   }
   return $Atv;
}

function AtAv(&$n,&$v){
   echo 'function AtAv(&$n,&$v){', "\n";
   $tmp = Av($n,$v);
   return Atv($n, $tmp);
}

function run_iter($n) {
  echo 'function run_iter($n) {', "\n";
  //$n = intval(($argc == 2) ? $argv[1] : 1);
  $u = array_fill(0, $n, 1.0);
  $_tpl = array_fill(0, $n, 0.0);

  for ($i=0; $i<10; $i++){
    echo 'for ($i=0; $i<10; $i++){', "\n";
    $v = AtAv($n,$u);
    $u = AtAv($n,$v);
  }

  $vBv = 0.0;
  $vv = 0.0;
  $i = 0;
  foreach($v as $val) {
    echo 'foreach($v as $val) {', "\n";
    $vBv += $u[$i]*$val;
    $vv += $val*$val;
    ++$i;
  }
  //printf("%0.9f\n", sqrt($vBv/$vv));
  sqrt($vBv/$vv); // other benchmarks don't do string formatting either
}
run_iter(3)
?>

