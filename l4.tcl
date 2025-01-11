set ns [new Simulator]
set tf [open 4.tr w]
$ns trace-all $tf
set nf [open 4.nam w]
$ns namtrace-all $nf

set s [$ns node]  ;# Server
set c [$ns node]  ;# Client

$ns color 1 Blue
$s label "Server"
$c label "Client"

$ns duplex-link $s $c 10Mb 22ms DropTail
$ns duplex-link-op $s $c orient right

set tcp_agent [new Agent/TCP]
$ns attach-agent $s $tcp_agent
$tcp_agent set packetSize_ 1500

set sink_agent [new Agent/TCPSink]
$ns attach-agent $c $sink_agent
$ns connect $tcp_agent $sink_agent

set ftp_app [new Application/FTP]
$ftp_app attach-agent $tcp_agent
$tcp_agent set fid_ 1

proc finish {} {
    global ns tf nf
    $ns flush-trace
    close $tf
    close $nf
    exec nam 4.nam &
    exec awk -f cal.awk 4.tr &
    exec awk -f con.awk 4.tr > convert.tr &
    exec xgraph convert.tr -geometry 800x400 -t "Bytes_received_at_Client" -x "Time_in_secs" -y "Bytes_in_bps" &
}

$ns at 0.01 "$ftp_app start"
$ns at 15.0 "$ftp_app stop"
$ns at 15.1 "finish"
$ns run

####calawk###

BEGIN {
    rcvd = 0;
    sent = 0;
}
{
    if ($1 == "r" && $4 == 1 && $5 == "tcp" && $6 > 0) {
        rcvd += $6; 
    }
    if ($1 == "+" && $3 == 0 && $5 == "tcp" && $6 > 0) {
        sent += $6;  
    }
}
END {
    if ($2 > 0) {
        printf("Time to transfer: %f\n", $2); 
    } else {
        printf("Invalid time data.\n");
    }
    printf("Sent: %f Mbps\n", sent / 1e6);
    printf("Received: %f Mbps\n", rcvd / 1e6);
}

####conawk###
BEGIN { count = 0 }

{
    if ($1 == "r" && $4 == 1 && $5 == "tcp") {
        count += $6; 
        printf("%f\t%f\n", $2, count / 1e6);  # Print time and cumulative data in Mbps
    }
}

AWK Script to convert file into graph values
BEGIN{
count=0;
time=0;
}
{
if($1=="r" && $4==1 && $5=="tcp")
{
count+=$6;
time=$2;
printf("\n%f\t%f",time,(count)/1000000);
}
} 
END{
}

AWK Script to calculate time required:
BEGIN{
count=0;
time=0;
total_bytes_received=0;
total_bytes_sent=0;
}
{
if($1=="r" && $4==1 && $5=="tcp")
total_bytes_received+=$6;
if($1=="+" && $3==0 && $5=="tcp")
total_bytes_sent+=$6;
} 
END{
system("clear");
printf("\nTransmission time required to transfer the file is %f",$2);
printf("\nActual data sent from the server is %f Mbps",
(total_bytes_sent)/1000000);
printf("\nData received by the client is %f Mbps\n",
(total_bytes_received)/1000000);
}

