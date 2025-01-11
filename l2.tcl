set ns [new Simulator]
set tr [open trace.tr w]
$ns trace-all $tr
set nam [open trace.nam w]
$ns namtrace-all $nam
set cw [open cw.tr w]
$ns color 1 blue
$ns color 2 red
set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]
set n4 [$ns node]
set n5 [$ns node]

$ns duplex-link $n0 $n2 2Mb 2ms DropTail
$ns duplex-link $n2 $n3 0.4Mb 5ms DropTail
$ns duplex-link $n1 $n2 2Mb 2ms DropTail
$ns duplex-link $n3 $n4 2Mb 2ms DropTail
$ns duplex-link $n3 $n5 2Mb 2ms DropTail
$ns queue-limit $n2 $n3 10

set tcp1 [new Agent/TCP]
set sink1 [new Agent/TCPSink]
set ftp [new Application/FTP]

$ns attach-agent $n0 $tcp1
$ns attach-agent $n5 $sink1
$ns connect $tcp1 $sink1
$ftp attach-agent $tcp1
$ns at 1.2 "$ftp start"

set tcp2 [new Agent/TCP]
set sink2 [new Agent/TCPSink]
set telnet [new Application/Telnet]

$ns attach-agent $n1 $tcp2
$ns attach-agent $n4 $sink2
$ns connect $tcp2 $sink2
$telnet attach-agent $tcp2
$ns at 5.1 "$telnet start"
$ns at 5.0 "$ftp stop"
$ns at 10.0 "finish"

proc plotWindow {tcp file} {
    global ns
    set interval 0.01
    set now [$ns now]
    set cwnd [$tcp set cwnd_]
    puts $file "$now $cwnd"
    $ns at [expr $now + $interval] "plotWindow $tcp $file"
}
$ns at 2.0 "plotWindow $tcp1 $cw"
$ns at 5.5 "plotWindow $tcp2 $cw"

proc finish {} {
    global ns tr nam cw
    $ns flush-trace
    close $tr
    close $nam
    close $cw
    puts "Running NAM..."
    exec nam trace.nam &
    puts "Running XGraph..."
    exec xgraph cw.tr &
    puts "Analyzing Trace File with AWK..."
    exec awk -f test.awk trace.tr &
    exit 0
}

$ns run

####awk###
BEGIN {
    tcp_drop = 0;
    udp_drop = 0;
}

{
    if ($1 == "d" && $5 == "tcp") {
        tcp_drop++;
    }
    if ($1 == "d" && $5 == "cbr") {
        udp_drop++;
    }
}

END {
    printf("Dropped TCP Packets: %d\n", tcp_drop);
    printf("Dropped UDP Packets: %d\n", udp_drop);
}


