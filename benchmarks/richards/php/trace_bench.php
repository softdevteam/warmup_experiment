<?php
// Ported by Maciej Fijalkowski to PHP (BSD license)

// Task IDs
define('I_IDLE', 1);
define('I_WORK', 2);
define('I_HANDLERA', 3);
define('I_HANDLERB', 4);
define('I_DEVA', 5);
define('I_DEVB', 6);

// Packet types
define('K_DEV', 1000);
define('K_WORK', 1001);

// Packet

define('BUFSIZE', 4);
$BUFSIZE_RANGE = array(0, 1, 2, 3);

class Packet {
	function __construct($l, $i, $k) {
		echo 'function __construct($l, $i, $k) {', "\n";
		$this->link = $l;
		$this->ident = $i;
		$this->kind = $k;
		$this->daturm = 0;
		$this->data = array(0, 0, 0, 0);
	}

	function append_to($lst) {
		echo 'function append_to($lst) {', "\n";
		$this->link = null;
		if ($lst === null) {
		        echo 'if ($lst === null) {', "\n";
			return $this;
                }
		$p = $lst;
		$next = $p->link;
		while ($next !== null) {
		        echo 'while ($next !== null) {', "\n";
			$p = $next;
			$next = $p->link;
		}
		$p->link = $this;
		return $lst;
	}
}

class TaskRec {}

class DeviceTaskRec extends TaskRec {
	function __construct() {
	        echo 'function __construct() {', "\n";
		$this->pending = null;
	}
}

class IdleTaskRec extends TaskRec {
	function __construct() {
	        echo 'function __construct() {', "\n";
		$this->control = 1;
		$this->count = 10000;
	}
}

class HandlerTaskRec extends TaskRec {
    function __construct() {
        echo 'function __construct() {', "\n";
        $this->work_in = null;
		$this->device_in = null;
	}

	function workInAdd($p) {
                echo 'function workInAdd($p) {', "\n";
		$x = $p->append_to($this->work_in);
		$this->work_in = $x;
		return $x;
	}

	function deviceInAdd($p) {
	        echo 'function deviceInAdd($p) {', "\n";
		$x = $p->append_to($this->device_in);
		$this->device_in = $x;
		return $x;
	}
}

class WorkTaskRec extends TaskRec {
	function __construct() {
	        echo 'function __construct() {', "\n";
		$this->destination = I_HANDLERA;
		$this->count = 0;
	}
}

class TaskState {
	function __construct() {
		echo 'function __construct() {', "\n";
		$this->packet_pending = true;
		$this->task_waiting = false;
		$this->task_holding = false;
	}

	function packetPending() {
		echo 'function packetPending() {', "\n";
		$this->packet_pending = true;
		$this->task_waiting = false;
		$this->task_holding = false;
		return $this;
	}

	function waiting() {
		echo 'function waiting() {', "\n";
		$this->packet_pending = false;
		$this->task_waiting = true;
		$this->task_holding = false;
		return $this;
	}
	
	function running() {
	 	echo 'function running() {', "\n";
		$this->packet_pending = false;
		$this->task_waiting = false;
		$this->task_holding = false;
		return $this;
	}

	function waitingWithPacket() {
		echo 'function waitingWithPacket() {', "\n";
		$this->packet_pending = true;
		$this->task_waiting = true;
		$this->task_holding = false;
		return $this;
	}
	
	function isPacketPending() {
		echo 'function isPacketPending() {', "\n";
		return $this->packet_pending;
	}

	function isTaskWaiting() {
		echo 'function isTaskWaiting() {', "\n";
		return $this->task_waiting;
	}

	function isTaskHolding() {
		echo 'function isTaskHolding() {', "\n";
		return $this->task_holding;
	}

	function isTaskHoldingOrWaiting() {
		echo 'function isTaskHoldingOrWaiting() {', "\n";
		return $this->task_holding || (!$this->packet_pending && $this->task_waiting);
	}

	function isWaitingWithPacket() {
		echo 'function isWaitingWithPacket() {', "\n";
		return $this->packet_pending && $this->task_waiting && !$this->task_holding;
	}
}

define('TASKTABSIZE', 10);

$layout = 0;

function trace($a) {
	echo 'function trace($a) {', "\n";
	global $layout;

	$layout--;
	if ($layout <= 0) {
		echo 'if ($layout <= 0) {', "\n";
		printf("\n");
		$layout = 50;
	}
	printf("%s ", $a);
}

class TaskWorkArea {
	function __construct() {
	echo 'function __construct() {', "\n";
        $this->reset();
    }

    function reset() {
    echo 'function reset() {', "\n";
		$this->taskTab = array();
		for ($i = 0; $i < TASKTABSIZE; $i++) {
		        echo 'for ($i = 0; $i < TASKTABSIZE; $i++) {', "\n";
			$this->taskTab[] = null;
		}
		$this->taskList = null;
		$this->holdCount = 0;
		$this->qpktCount = 0;
	}
}

class Task extends TaskState {
	function __construct($i, $p, $w, $initialState, $r) {
	        echo 'function __construct($i, $p, $w, $initialState, $r) {', "\n";
		global $taskWorkArea;

		$this->link = $taskWorkArea->taskList;
		$this->ident = $i;
		$this->priority = $p;
		$this->input = $w;

		$this->packet_pending = $initialState->isPacketPending();
		$this->task_waiting = $initialState->isTaskWaiting();
		$this->task_holding = $initialState->isTaskHolding();
		
		$this->handle = $r;

		$taskWorkArea->taskList = $this;
		$taskWorkArea->taskTab[$i] = $this;
	}

	function addPacket($p, $old) {
	        echo 'function addPacket($p, $old) {', "\n";
		if ($this->input === null) {
		        echo 'if ($this->input === null) {', "\n";
			$this->input = $p;
			$this->packet_pending = true;
			if ($this->priority > $old->priority) {
		     	        echo 'if ($this->priority > $old->priority) {', "\n";
				return $this;
			}
		} else {
		        echo '} else {', "\n";
			$p->append_to($this->input);
		}
		return $old;
	}

	function runTasks() {
	        echo 'function runTasks() {', "\n";
		if ($this->isWaitingWithPacket()) {
		        echo 'if ($this->isWaitingWithPacket()) {', "\n";
			$msg = $this->input;
			$this->input = $msg->link;
			if ($this->input === null) {
			        echo 'if ($this->input === null) {', "\n";
		 		$this->running();
			} else {
			        echo '} else {', "\n";
				$this->packetPending();
			}
		} else {
		        echo '} else {', "\n";
			$msg = null;
		}
		return $this->fn($msg, $this->handle);
	}

	function waitTask() {
	        echo 'function waitTask() {', "\n";
		$this->task_waiting = true;
		return $this;
	}

	function hold() {
	        echo 'function hold() {', "\n";
		global $taskWorkArea;

		$taskWorkArea->holdCount += 1;
		$this->task_holding = true;
		return $this->link;
	}

	function release($i) {
	        echo 'function release($i) {', "\n";
		$t = $this->findtcb($i);
		$t->task_holding = false;
		if ($t->priority > $this->priority) {
		        echo 'if ($t->priority > $this->priority) {', "\n";
			return $t;
		} else {
		        echo '} else {', "\n";
			return $this;
		}
	}

	function qpkt($pkt) {
	        echo 'function qpkt($pkt) {', "\n";
		global $taskWorkArea;
		$t = $this->findtcb($pkt->ident);
		$taskWorkArea->qpktCount += 1;
		$pkt->link = null;
		$pkt->ident = $this->ident;
		return $t->addPacket($pkt, $this);
	}

	function findtcb($id) {
	        echo 'function findtcb($id) {', "\n";
		global $taskWorkArea;
		$t = $taskWorkArea->taskTab[$id];
		if ($t === null) {
		        echo 'if ($t === null) {', "\n";
			throw new Exception("Bad task id");
		}
		return $t;
	}
}

class DeviceTask extends Task {
	function fn($pkt, $r) {
	        echo 'function fn($pkt, $r) {', "\n";
		$d = $r;
		if (!($d instanceof DeviceTaskRec)) {
		        echo 'if (!($d instanceof DeviceTaskRec)) {', "\n";
			throw new Exception("not a DeviceTaskRec");
		}
		if ($pkt == null) {
		        echo 'if ($pkt == null) {', "\n";
			$pkt = $d->pending;
			if ($pkt === null)
			        echo 'if ($pkt === null)', "\n";
				return $this->waitTask();
			$d->pending = null;
			return $this->qpkt($pkt);
		}
		$d->pending = $pkt;
		if (TRACING) {
		        echo 'if (TRACING) {', "\n";
			trace($pkt->datum);
		}
		return $this->hold();
	}
}

class HandlerTask extends Task {
	function fn($pkt, $r) {
	        echo 'function fn($pkt, $r) {', "\n";
		$h = $r;
		if (!($h instanceof HandlerTaskRec)) {
		        echo 'if (!($h instanceof HandlerTaskRec)) {', "\n";
			throw new Exception("not a HandlerTaskRec");
		}
		if ($pkt !== null) {
		        echo 'if ($pkt !== null) {', "\n";
			if ($pkt->kind == K_WORK) {
			        echo 'if ($pkt->kind == K_WORK) {', "\n";
				$h->workInAdd($pkt);
                        }
			else {
			        echo 'else {', "\n";
				$h->deviceInAdd($pkt);
                        }
		}
		$work = $h->work_in;
		if ($work === null) {
		        echo 'if ($work === null) {', "\n";
			return $this->waitTask();
                }
		$count = $work->datum;
		if ($count >= BUFSIZE) {
		        echo 'if ($count >= BUFSIZE) {', "\n";
			$h->work_in = $work->link;
			return $this->qpkt($work);
		}

		$dev = $h->device_in;
		if ($dev === null)
		        echo 'if ($dev === null)', "\n";
			return $this->waitTask();

		$h->device_in = $dev->link;
		$dev->datum = $work->data[$count];
		$work->datum = $count + 1;
		return $this->qpkt($dev);
	}
}

class IdleTask extends Task {
	function fn($pkt, $r) {
	        echo 'function fn($pkt, $r) {', "\n";
		$i = $r;
		if (!($i instanceof IdleTaskRec)) {
		        echo 'if (!($i instanceof IdleTaskRec)) {', "\n";
			throw new Exception("not an IdleTaskRec");
		}
		$i->count -= 1;
		if ($i->count == 0) {
		        echo 'if ($i->count == 0) {', "\n";
			return $this->hold();
                }
		else if (($i->control & 1) == 0) {
		        echo 'else if (($i->control & 1) == 0) {', "\n";
			$i->control = $i->control / 2;
			return $this->release(I_DEVA);
		}
		$i->control = ($i->control / 2) ^ 0xd008;
		return $this->release(I_DEVB);
	}
}

class WorkTask extends Task {
	function fn($pkt, $r) {
	        echo 'function fn($pkt, $r) {', "\n";
		$w = $r;
		if ($pkt === null) {
		        echo 'if ($pkt === null) {', "\n";
			return $this->waitTask();
                }

		if ($w->destination == I_HANDLERA) {
		        echo 'if ($w->destination == I_HANDLERA) {', "\n";
			$dest = I_HANDLERB;
                } else {
                        echo '} else {', "\n";
			$dest = I_HANDLERA;
                }

		$w->destination = $dest;
		$pkt->ident = $dest;
		$pkt->datum = 0;

		for ($i = 0; $i < BUFSIZE; $i++) {
		        echo 'for ($i = 0; $i < BUFSIZE; $i++) {', "\n";
			$w->count += 1;
			if ($w->count > 26) {
			        echo 'if ($w->count > 26) {', "\n";
				$w->count = 1;
                        }
			$pkt->data[$i] = ord("A") + $w->count - 1;
		}

		return $this->qpkt($pkt);
	}
}

define('TRACING', 0);

function schedule() {
        echo 'function schedule() {', "\n";
	global $taskWorkArea;

	$t = $taskWorkArea->taskList;
	while ($t !== null) {
                echo 'while ($t !== null) {', "\n";
		$pkt = null;
		if (TRACING) {
		        echo 'if (TRACING) {', "\n";
			printf("tcb = %d\n", $t->ident);
                }
		if ($t->isTaskHoldingOrWaiting()) {
		        echo 'if ($t->isTaskHoldingOrWaiting()) {', "\n";
			$t = $t->link;
                } else {
                        echo '} else {', "\n";
			if (TRACING) {
		                echo 'if (TRACING) {', "\n";
				trace(chr(ord("0") + $t->ident));
                        }
			$t = $t->runTasks();
		}
	}
}

class Richards {

	function run($iterations) {
	        echo 'function run($iterations) {', "\n";
		global $taskWorkArea;

		for ($i = 0; $i < $iterations; $i++) {
		        echo 'for ($i = 0; $i < $iterations; $i++) {', "\n";
                        $taskWorkArea->reset();
			//$taskWorkArea->holdCount = 0;
			//$taskWorkArea->qpktCount = 0;
			$task_state = new TaskState();
			new IdleTask(I_IDLE, 1, 10000, $task_state->running(),
						 new IdleTaskRec());

			$wkq = new Packet(null, 0, K_WORK);
			$wkq = new Packet($wkq, 0, K_WORK);
			$task_state = new TaskState();
			new WorkTask(I_WORK, 1000, $wkq, $task_state->waitingWithPacket(),
						 new WorkTaskRec());

			$wkq = new Packet(null, I_DEVA, K_DEV);
			$wkq = new Packet($wkq, I_DEVA, K_DEV);
			$wkq = new Packet($wkq, I_DEVA, K_DEV);
			$task_state = new TaskState();
			new HandlerTask(I_HANDLERA, 2000, $wkq,
							$task_state->waitingWithPacket(),
							new HandlerTaskRec());

			$wkq = new Packet(null, I_DEVB, K_DEV);
			$wkq = new Packet($wkq, I_DEVB, K_DEV);
			$wkq = new Packet($wkq, I_DEVB, K_DEV);
			$task_state = new TaskState();
			new HandlerTask(I_HANDLERB, 3000, $wkq,
							$task_state->waitingWithPacket(),
							new HandlerTaskRec());
			
			$wkq = null;
			
			$task_state = new TaskState();
			new DeviceTask(I_DEVA, 4000, $wkq, $task_state->waiting(),
						   new DeviceTaskRec());
			$task_state = new TaskState();
			new DeviceTask(I_DEVB, 5000, $wkq, $task_state->waiting(),
						   new DeviceTaskRec());

			schedule();

			if (!($taskWorkArea->holdCount == 9297 && $taskWorkArea->qpktCount == 23246)) {
			        echo 'if (!($taskWorkArea->holdCount == 9297 && $taskWorkArea->qpktCount == 23246)) {', "\n";
				return false;
                        }
		}
		return true;
	}
}

$taskWorkArea = new TaskWorkArea();

/*
$number_of_runs = 100;
if ($argc > 1) {
	$number_of_runs = $argv[1] + 0;
}
$r = new Richards();
$t0 = microtime(true);
$res = $r->run($number_of_runs);
$t1 = microtime(true);
if (!$res) {
	printf("Incorrect result!\n");
} else {
	printf("finished\n");
	$total = $t1 - $t0;
	printf("Total time for $number_of_runs iterations: $total\n");
	$ms = $total * 1000 / $number_of_runs;
	printf("Average time per iteration: $ms\n");
}
*/

function run_iter($n) {
    echo 'function run_iter($n) {', "\n";
    $r = new Richards();
    $res = $r->run($n);
    assert($res);
}


?>
