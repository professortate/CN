# Set simulation parameters
set val(chan) Channel/WirelessChannel
set val(prop) Propagation/TwoRayGround
set val(netif) Phy/WirelessPhy
set val(mac) Mac/802_11
set val(ifq) Queue/DropTail/PriQueue
set val(ll) LL
set val(ant) Antenna/OmniAntenna
set val(x) 500
set val(y) 500
set val(ifqlen) 50
set val(nn) 6        ;# Number of nodes
set val(stop) 100.0  ;# Simulation time
set val(rp) AODV     ;# Routing protocol

# Initialize the simulator
set ns_ [new Simulator]

# Open trace and NAM trace files
set tracefd [open 003.tr w]
$ns_ trace-all $tracefd
set namtrace [open 003.nam w]
$ns_ namtrace-all-wireless $namtrace $val(x) $val(y)

# Define propagation model
set prop [new $val(prop)]
set topo [new Topography]
$topo load_flatgrid $val(x) $val(y)

# Create a god object (for network monitoring)
set god_ [create-god $val(nn)]

# Node Configuration
$ns_ node-config -adhocRouting $val(rp) \
-llType $val(ll) \
-macType $val(mac) \
-ifqType $val(ifq) \
-ifqLen $val(ifqlen) \
-antType $val(ant) \
-propType $val(prop) \
-phyType $val(netif) \
-channelType $val(chan) \
-topoInstance $topo \
-agentTrace ON \
-routerTrace ON \
-macTrace ON

# Create nodes and set initial positions
for {set i 0} {$i < $val(nn)} {incr i} {
    set node_($i) [$ns_ node]
    # Enable random motion for all nodes
    $node_($i) random-motion 1  ;# 1 enables random motion
    set xx [expr rand()*500]
    set yy [expr rand()*400]
    $node_($i) set X_ $xx
    $node_($i) set Y_ $yy
}

# Set initial positions for all nodes (you can modify this as needed)
$node_(0) set X_ 100.0
$node_(0) set Y_ 100.0
$node_(1) set X_ 300.0
$node_(1) set Y_ 100.0
$node_(2) set X_ 500.0
$node_(2) set Y_ 100.0
$node_(3) set X_ 100.0
$node_(3) set Y_ 300.0
$node_(4) set X_ 300.0
$node_(4) set Y_ 300.0
$node_(5) set X_ 500.0
$node_(5) set Y_ 300.0

# Initial node positions
for {set i 0} {$i < $val(nn)} {incr i} {
    $ns_ initial_node_pos $node_($i) 40
}

# Set up TCP traffic (directly in the script instead of sourcing a file)
set tcp0 [new Agent/TCP]
set sink0 [new Agent/TCPSink]
$ns_ attach-agent $node_(0) $tcp0
$ns_ attach-agent $node_(2) $sink0
$ns_ connect $tcp0 $sink0
set ftp0 [new Application/FTP]
$ftp0 attach-agent $tcp0
$ns_ at 1.0 "$ftp0 start"
$ns_ at 50.0 "$ftp0 stop"

set tcp1 [new Agent/TCP]
set sink1 [new Agent/TCPSink]
$ns_ attach-agent $node_(1) $tcp1
$ns_ attach-agent $node_(3) $sink1
$ns_ connect $tcp1 $sink1
set ftp1 [new Application/FTP]
$ftp1 attach-agent $tcp1
$ns_ at 1.0 "$ftp1 start"
$ns_ at 50.0 "$ftp1 stop"

set tcp2 [new Agent/TCP]
set sink2 [new Agent/TCPSink]
$ns_ attach-agent $node_(4) $tcp2
$ns_ attach-agent $node_(5) $sink2
$ns_ connect $tcp2 $sink2
set ftp2 [new Application/FTP]
$ftp2 attach-agent $tcp2
$ns_ at 1.0 "$ftp2 start"
$ns_ at 50.0 "$ftp2 stop"

# Simulation Termination
for {set i 0} {$i < $val(nn)} {incr i} {
    $ns_ at $val(stop) "$node_($i) reset"
}
$ns_ at $val(stop) "puts \"NS EXITING...\" ; $ns_ halt"

puts "Starting Simulation..."
$ns_ run

