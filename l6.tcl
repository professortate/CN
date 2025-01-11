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
set val(nn) 2  ;# number of nodes
set val(stop) 20.0  ;# simulation duration (seconds)
set val(rp) DSDV  ;# routing protocol (DSDV)

# Initialize the simulator
set ns [new Simulator]

# Create trace files for simulation
set tracefd [open 001.tr w]
$ns trace-all $tracefd
set namtrace [open 001.nam w]
$ns namtrace-all-wireless $namtrace $val(x) $val(y)

# Set up propagation model and topology
set prop [new $val(prop)]
set topo [new Topography]
$topo load_flatgrid $val(x) $val(y)

# Create the "God" (for simulation nodes)
create-god $val(nn)

# Configure the nodes
$ns node-config -adhocRouting $val(rp) \
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

# Create nodes and enable random motion
for {set i 0} { $i < $val(nn) } { incr i } {
    set node_($i) [$ns node]
    $node_($i) random-motion 0
}

# Set initial positions for the nodes
for {set i 0} { $i < $val(nn) } { incr i } {
    $ns initial_node_pos $node_($i) 40  ;# Set random initial positions
}

# Set destination for the nodes at time 1.1 seconds
$ns at 1.1 "$node_(0) setdest 310.0 10.0 20.0"
$ns at 1.1 "$node_(1) setdest 10.0 310.0 20.0"

# Generating TCP traffic
set tcp0 [new Agent/TCP]
set sink0 [new Agent/TCPSink]
$ns attach-agent $node_(0) $tcp0
$ns attach-agent $node_(1) $sink0
$ns connect $tcp0 $sink0

# Attach FTP application to the TCP agent
set ftp0 [new Application/FTP]
$ftp0 attach-agent $tcp0

# Start and stop FTP traffic
$ns at 1.0 "$ftp0 start"
$ns at 18.0 "$ftp0 stop"

# Reset nodes at the end of the simulation
for {set i 0} { $i < $val(nn) } { incr i } {
    $ns at $val(stop) "$node_($i) reset"
}

# Output message to indicate simulation start
puts "Starting simulation..."

# Schedule the end of the simulation and output exit message
$ns at $val(stop) "puts \"NS EXITING...\"; finish"

# Define the finish procedure to end the simulation, close files, and run NAM
proc finish {} {
    global ns tracefd namtrace
    $ns flush-trace
    close $tracefd
    close $namtrace
    exec nam 001.nam &  ;# Start NAM to visualize the simulation
    exit 0
}

# Run the simulation
$ns run

