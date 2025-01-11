set ns [new Simulator]
set tf [open sim.tr w]
$ns trace-all $tf

set nf [open sim.nam w]
$ns namtrace-all $nf

set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]

$ns duplex-link $n0 $n2 2Mb 2ms DropTail
$ns duplex-link $n1 $n2 2Mb 2ms DropTail
$ns duplex-link $n2 $n3 0.4Mb 10ms DropTail
$ns queue-limit $n2 $n3 5

set u1 [new Agent/UDP]
$ns attach-agent $n0 $u1

set na [new Agent/Null]
$ns attach-agent $n3 $na
$ns connect $u1 $na

set c1 [new Application/Traffic/CBR]
$c1 attach-agent $u1
$ns at 1.1 "$c1 start"

set t1 [new Agent/TCP]
$ns attach-agent $n1 $t1

set s1 [new Agent/TCPSink]
$ns attach-agent $n3 $s1
$ns connect $t1 $s1

set f1 [new Application/FTP]
$f1 attach-agent $t1
$ns at 0.1 "$f1 start"
$ns at 10.0 "done"

proc done {} {
    global ns tf nf
    $ns flush-trace
    close $tf
    close $nf
    puts "Running NAM..."
    exec nam sim.nam &
    # Call the AWK script to process the trace file
    exec awk -f sim.awk sim.tr &
    exit 0
}

$ns run


#######awk###
BEGIN {
tcp_count=0;
udo_count=0;
}{
if($1 == "d" && $5 == "tcp")
tcp_count++;
if($1 == "d" && $5 == "cbr")
udp_count++;
} END {
printf("TCP %d\n",tcp_count);
printf("UDP %d\n",udp_count);
}

