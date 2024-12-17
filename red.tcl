set ns [new Simulator]
set sduration 20
set simTime 20
set processing_dir processing
set red_dir $processing_dir/red
set qm_dir $processing_dir/qm
set nam_dir $processing_dir/nam

file mkdir $processing_dir
file mkdir $red_dir
file mkdir $qm_dir
file mkdir $nam_dir

# Получаем параметры из аргументов командной строки
if { $argc == 2 } {
	set Qmin [lindex $argv 0]
	set Qmax [lindex $argv 1]
	#puts "Running simulation with Qmin=$Qmin and Qmax=$Qmax"
	set suffix "${Qmin}_${Qmax}"
	# Настройка параметров RED, если указаны
	Queue/RED set thresh_ $Qmin
	Queue/RED set maxthresh_ $Qmax
} else {
	set suffix "default"
	#puts "Running without parameters Qmin and Qmax..."
}


set nf [open ${nam_dir}/out_${suffix}.nam w]
$ns namtrace-all $nf

# Настройка оставшихся параметров RED
Queue/RED set q_weight_ 0.002
Queue/RED set setbit_ false
Queue/RED set bytes_ false
Queue/RED set queue_in_bytes_ false
Queue/RED set gentle_ false
Queue/RED set mean_pktsize_ 1000
Queue/RED set cur_max_p_ 0.1

# Продолжаем с созданием нод и связей
set numSrc 60

set R1 [$ns node]
set R2 [$ns node]

# Создание источников и приемников
for {set i 1} {$i<=$numSrc} {incr i} {
	# Create node
	set n($i) [$ns node]
	# Create link
	$ns duplex-link $n($i) $R1 100Mb 20ms DropTail
	# Create TCP agent on node n($i)
	set tcp($i) [new Agent/TCP/Reno]
	$tcp($i) set window_ 32
	$tcp($i) set fid_ 2
	$tcp($i) set paketSize_ 1000
	$tcp($i) set class_ 1

	$ns attach-agent $n($i) $tcp($i)
	# FTP
	set ftp($i) [new Application/FTP]
	$ftp($i) attach-agent $tcp($i)
	$ftp($i) set type_ FTP

	# Create sink
	set s($i) [$ns node]
	# Create link
	$ns duplex-link $s($i) $R2 100Mb 20ms DropTail
	# Create sink agent on node s($i)
	set sink($i) [new Agent/TCPSink]
	$ns attach-agent $s($i) $sink($i)

	# Connect n($i) and s($i)
	$ns connect $tcp($i) $sink($i)
}

set flink [$ns simplex-link $R1 $R2 20Mb 35ms RED]
$ns simplex-link $R2 $R1 20Mb 35ms DropTail
$ns queue-limit $R1 $R2 300

set qmon [$ns monitor-queue $R1 $R2 [open ${qm_dir}/qm_${suffix}.tr w] 0.01]
[$ns link $R1 $R2] queue-sample-timeout

set redq [[$ns link $R1 $R2] queue]
set traceq [open ${red_dir}/red-queue_${suffix}.tr w]
$redq trace curq_
$redq trace ave_
$redq attach $traceq

# Obtaining TCP CWND Window information

# plotWindow(tcpSource file k): Write CWND of k tcpSources in file
# The output format is as follows:
# TIME Win_flow1 Win_flow2 Win_flow3 ... Win_flowN

# Функция для записи TCP окна
proc plotWindow {tcpSource file k} {
	global ns numSrc

	set time 0.03
	set now [$ns now]
	set cwnd [$tcpSource set cwnd_]

	if {$k == 1} {
		puts -nonewline $file "$now \t $cwnd \t"
	} else {
		if {$k < $numSrc } {
			puts -nonewline $file "$cwnd \t"
		}
	}

	if { $k == $numSrc } {
		puts -nonewline $file "$cwnd \n"
	}

	if { $k == $numSrc } {
		puts -nonewline $file "$cwnd \n"
	}
	$ns at [expr $now+$time] "plotWindow $tcpSource $file $k"
}

# Start plotWindow() for all tcp sources
# Output to stdout
for {set j 1} {$j<=$numSrc} { incr j } {
	$ns at 0.1 "plotWindow $tcp($j) stdout $j"
}

proc finish {} {
	exit 0
}

for {set i 1} {$i<=$numSrc} {incr i} {
	$ns at 0.0 "$ftp($i) start"
	$ns at $simTime "$ftp($i) stop"
	# $ns at $simTime "calc_throughput $tcpsrc($j) $j $simTime"
}

$ns at $simTime "finish"
$ns run

