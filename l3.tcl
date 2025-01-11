set ns [new Simulator]
set tr [open ex3.tr w]
$ns trace-all $tr
set nam [open ex3.nam w]
$ns namtrace-all $nam
set cw [open win3.tr w]

$ns color 1 Blue
$ns color 2 Red
$ns rtproto DV

set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]
set n4 [$ns node]
set n5 [$ns node]

$ns duplex-link $n0 $n1 0.3Mb 10ms DropTail
$ns duplex-link $n0 $n2 0.3Mb 10ms DropTail
$ns duplex-link $n2 $n3 0.3Mb 10ms DropTail
$ns duplex-link $n1 $n4 0.3Mb 10ms DropTail
$ns duplex-link $n3 $n5 0.5Mb 10ms DropTail
$ns duplex-link $n4 $n5 0.5Mb 10ms DropTail

$ns duplex-link-op $n0 $n1 orient right-up
$ns duplex-link-op $n0 $n2 orient right-down
$ns duplex-link-op $n2 $n3 orient right
$ns duplex-link-op $n1 $n4 orient right
$ns duplex-link-op $n3 $n5 orient right-up
$ns duplex-link-op $n4 $n5 orient right-down

set tcp1 [new Agent/TCP]
set sink1 [new Agent/TCPSink]
$ns attach-agent $n0 $tcp1
$ns attach-agent $n4 $sink1
$ns connect $tcp1 $sink1
$tcp1 set fid_ 1

set ftp1 [new Application/FTP]
$ftp1 attach-agent $tcp1

$ns rtmodel-at 1.0 down $n1 $n4
$ns rtmodel-at 3.0 up $n1 $n4

$ns at 0.1 "$ftp1 start"
$ns at 12.0 "finish"

proc plotWindow {tcp file} {
    global ns
    set time 0.01
    set now [$ns now]
    set cwnd [$tcp set cwnd_]
    puts $file "$now $cwnd"
    $ns at [expr $now + $time] "plotWindow $tcp $file"
}

$ns at 1.0 "plotWindow $tcp1 $cw"

proc finish {} {
    global ns tr nam cw
    $ns flush-trace
    close $tr
    close $nam
    close $cw
    exec nam ex3.nam &
    exec xgraph win3.tr &
    puts "Running AWK analysis on the trace file..."
    exec awk -f test.awk ex3.tr &
    exit 0
}

$ns run

#####awk####
BEGIN {
    tcp_drop = 0;
    udp_drop = 0;
    total_tcp = 0;
    total_udp = 0;
}

{
    if ($1 == "d" && $5 == "tcp") {
        tcp_drop++;
    }
    if ($1 == "d" && $5 == "cbr") {
        udp_drop++;
    }
    if ($5 == "tcp") {
        total_tcp++;
    }
    if ($5 == "cbr") {
        total_udp++;
    }
}

END {
    print "TCP Sent Packets: " total_tcp;
    print "UDP Sent Packets: " total_udp;
    print "Dropped TCP Packets: " tcp_drop;
    print "Dropped UDP Packets: " udp_drop;
}



