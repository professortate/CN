set ns [new Simulator -multicast on]
$ns multicast

# Tracing
set tf [open mcast.tr w]
$ns trace-all $tf
set fd [open mcast.nam w]
$ns namtrace-all $fd

# Create nodes
set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]
set n4 [$ns node]
set n5 [$ns node]
set n6 [$ns node]
set n7 [$ns node]

# Create links
$ns duplex-link $n0 $n2 1.5Mb 10ms DropTail
$ns duplex-link $n1 $n2 1.5Mb 10ms DropTail
$ns duplex-link $n2 $n3 1.5Mb 10ms DropTail
$ns duplex-link $n3 $n4 1.5Mb 10ms DropTail
$ns duplex-link $n3 $n7 1.5Mb 10ms DropTail
$ns duplex-link $n4 $n5 1.5Mb 10ms DropTail
$ns duplex-link $n4 $n6 1.5Mb 10ms DropTail

# Multicast protocol
set mproto DM
set mrthandle [$ns mrtproto $mproto {}]

# Allocate group addresses
set g1 [Node allocaddr]
set g2 [Node allocaddr]

# UDP source agents
set udp0 [new Agent/UDP]
$ns attach-agent $n0 $udp0
$udp0 set dst_addr_ $g1
$udp0 set dst_port_ 0
set cbr1 [new Application/Traffic/CBR]
$cbr1 attach-agent $udp0

set udp1 [new Agent/UDP]
$ns attach-agent $n1 $udp1
$udp1 set dst_addr_ $g2
$udp1 set dst_port_ 0
set cbr2 [new Application/Traffic/CBR]
$cbr2 attach-agent $udp1

# Receiver agents
set rcv1 [new Agent/Null]
$ns attach-agent $n5 $rcv1
$ns at 1.0 "$n5 join-group $rcv1 $g1"
set rcv2 [new Agent/Null]
$ns attach-agent $n6 $rcv2
$ns at 1.5 "$n6 join-group $rcv2 $g1"
set rcv3 [new Agent/Null]
$ns attach-agent $n7 $rcv3
$ns at 2.0 "$n7 join-group $rcv3 $g1"
set rcv4 [new Agent/Null]
$ns attach-agent $n5 $rcv4
$ns at 2.5 "$n5 join-group $rcv4 $g2"
set rcv5 [new Agent/Null]
$ns attach-agent $n6 $rcv5
$ns at 3.0 "$n6 join-group $rcv5 $g2"
set rcv6 [new Agent/Null]
$ns attach-agent $n7 $rcv6
$ns at 3.5 "$n7 join-group $rcv6 $g2"

# Leave groups
$ns at 4.0 "$n5 leave-group $rcv1 $g1"
$ns at 4.5 "$n6 leave-group $rcv2 $g1"
$ns at 5.0 "$n7 leave-group $rcv3 $g1"
$ns at 5.5 "$n5 leave-group $rcv4 $g2"
$ns at 6.0 "$n6 leave-group $rcv5 $g2"
$ns at 6.5 "$n7 leave-group $rcv6 $g2"

# Schedule events
$ns at 0.5 "$cbr1 start"
$ns at 9.5 "$cbr1 stop"
$ns at 0.5 "$cbr2 start"
$ns at 9.5 "$cbr2 stop"
$ns at 10.0 "finish"

# Finish procedure
proc finish {} {
    global ns tf fd
    $ns flush-trace
    close $tf
    close $fd
    exec nam mcast.nam &
    exit 0
}

# Labels and colors for nodes
$n0 label "Src1"
$n1 label "Src2"
$n5 label "Rcvr1"
$n6 label "Rcvr2"
$n7 label "Rcvr3"

$ns color 1 red
$ns color 2 green
$n5 color blue
$n6 color blue
$n7 color blue

$ns run

####awk####
BEGIN {
    sent1 = 0; recv1 = 0; sent2 = 0; recv2 = 0
}

{
    # Check for sent packets (group 1 or group 2)
    if ($1 == "+" && $5 == "cbr") {
        if ($3 == 4) sent1 += $6  # Sent from node 4 (Group 1)
        if ($3 == 5) sent2 += $6  # Sent from node 5 (Group 2)
    }

    # Check for received packets (group 1 or group 2)
    if ($1 == "r" && $5 == "cbr") {
        if ($3 == 4) recv1 += $6  # Received at node 4 (Group 1)
        if ($3 == 5) recv2 += $6  # Received at node 5 (Group 2)
    }
}

END {
    # Print results in Mbps
    print "Group 1 Sent: ", sent1 / 1e6, "Mbps  Recvd: ", recv1 / 1e6, "Mbps"
    print "Group 2 Sent: ", sent2 / 1e6, "Mbps  Recvd: ", recv2 / 1e6, "Mbps"
}



