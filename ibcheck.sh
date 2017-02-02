#!/bin/bash

# Author: Le Yan @ LSU
# v0.2: Feb 2, 2017

# To do:
# 1. Add the latency test;
# 2. Detect the "bad" pair automatically;

# Known issues:

# Check latency and bandwidth between nodes

usage() {
  cat << HERE

  Description:
    This script runs point-to-point bandwidth and latency tests between specified nodes.
    The bandwidth between two hosts is measured using the "ib_read_bw" command.
    The latnecy between two hosts is measured using the "ib_read_lat" command.

  Requirement:
    To generate to the heatmap, one must have R and the "ggplot2" package installed.

  Usage:
    $0 [options]

  Options:
    -t: type of tests - "bw" for bandwidth, "lat" for latency or "both" for both;
    -n: name of tests - this value will decide the names the files generated;
    -f: name of the host file; 
    -r: name and range of hosts;
    -v: verbose mode; for debugging;
    -h: help message;

  Examples:
    $0 -t bw		      : Perform bandwidth test.
    $0 -t lat		      : Perform latency test.
    $0 -f hostlist -t both    : Perform both bandwidth and latency tests on the hosts specified by the file "hostlist".
    $0 -r mike 100 200 -t lat : Perform latency test on the nodes between mike100 and mike200.

HERE
}

function quit_on_error {
  echo
  echo "Error:"
  echo $1
  echo
  exit 1
}

# Set default values for some parameters.

verbose=0
hostfile=
nstart=
nend=
name=

# Some parameters are hard-coded.
# bw_expect: expected bandwidth (MB/s)
# lat_expect: expected latency (micro seconds)

datafile="test.dat"
bw_expect="3700"
lat_expect=
sleep_len="1"

# Process command line arguments.

if [ "$#" -eq 0 ] 
then
  usage
  exit
fi

while [ "$#" -gt 0 ] ; do
case "$1" in
  -t)
	ttype="$2";
        shift 2;;
  -n)
	name="$2";
        shift 2;;
  -f)
        hostfile="$2";
        shift 2;;
  -r)
	hn=$2;
	nstart=$3;
	nend=$4;
	shift 4
	;;
  -v)
        verbose=1;
        shift;;
  -h)
        usage
        exit
        ;;
  *)
        echo "Invalid option: $1"
        usage
        exit
        ;;
esac
done

# Sanity checks.

# Type has to be "bw" or "lat" or "both".
if [[ $ttype != "bw" && $ttype != "lat" && $ttype != "both" ]]
then
  quit_on_error "The type of test should be 'bw', 'lat' or 'both'."
fi

# If a name is not given, use the time stamp as default name.
if [ -z $name ]
then
  name=`date +%Y%m%d_%H%M%S`
fi

# The bounds of the nodes must be numbers.

re='^[0-9]+$'
if ! [[ -z $nstart ]]
then
  if ! [[ $nstart =~ $re ]]
  then
    quit_on_error "Please check the node numbers!"
  fi
fi

if ! [[ -z $nend ]]
then
  if ! [[ $nend =~ $re ]]
  then
    quit_on_error "Please check the node numbers!"
  fi
fi

# Cannot use "-r" and "-f" together.
if [[ -n $nstart && -n $hostfile ]]
then
  quit_on_error "Please specify either a hostfile or a range of hosts."
fi

# Check if the specified host file exists.
if [[ -n $hostfile && ! -f $hostfile ]]
then
  quit_on_error "The hostfile $hostfile does not exist."
fi

datafile=$name".dat"
rscript=$name".R"
map_bw=$name"_map_bw.png"
map_lat=$name"_map_lat.png"

# Create the list of hosts to be tested.
# By default, the list includes all nodes reported "online" by Moab.
# If a subset of nodes are to be tested, either a node range or
# a host file can be supplied.

# All nodes that are report by Moab as "online".
mlist=`mdiag -n -v | grep -vi drained | awk '{print $1}' | head -n -4 | tail -n +4`
templist=
list=

if [[ -n $hostfile ]]
then
  templist=`cat $hostfile | sort | uniq`
elif [[ -n $nstart ]]
then
  for i in $(seq -f "%03g" $nstart $nend)
  do
    templist="$templist $hn$i"
  done
else
  quit_on_error "Please specify either a hostfile or a range of hosts."
  exit
fi

# Generate the list of online nodes reported by Moab.

for host in `echo $templist`
do
  if [[ $mlist =~ .*$host.* ]]
  then
    list="$list $host"
  fi
done

if [[ -z $list ]]
then
  quit_on_error "No host can be found."
fi

# Rough estimate of how long the test will take.
#nhost=`echo $list | wc -w`
#esttime=`echo "($sleep_len+1.3)*$nhost*($nhost-1)" | bc`
#echo
#echo "The test will take approximately $esttime seconds."
#echo

# Write data file header.

if [ $ttype == "both" ]
then
  header="node1 node2 bw lat"
elif [ $ttype == "bw" ]
then 
  header="node1 node2 bw"
else
  header="node1 node2 lat"
fi
echo $header > $datafile

# Bandwidth and latency tests.

# Test bandwidth.
for host1 in $list
do
  #row="$host1"
  >&2 echo "Testing $host1..."
  for host2 in $list
  do
    if [[ $host1 != $host2 ]]
    then
      #echo "Testing $host1 and $host2..."
      if [ $ttype == "both" -o $ttype == "bw" ]
      then 
	# Start the server on host1.
        ssh -n $host1 "ib_read_bw" > /dev/null &
	# Make sure the server is successfully started. If not, wait a bit.
	ssh -n $host1 "ps aux | grep ib_read_bw | grep -v grep" > /dev/null
	if [[ $? != 0 ]]
	then
          sleep $sleep_len
	fi
	# Start on host2.
        bw=`ssh -n $host2 "ib_read_bw $host1" | tail -2 | head -1 | awk '{print $4}' &`
        wait
        #echo "Bandwidth: $bw MB/s"
        #row=$row",$bw"
        echo "$host1 $host2 $bw"
      fi
    else
      echo "$host1 $host1 $bw_expect"
    fi
  done
#  echo $row
done >> $datafile

# Create a R script to generate the heatmap.
cat >$rscript << HERE
library(ggplot2)
bw <- read.table(file="$datafile",header=TRUE)
g <- ggplot(bw,aes(x=node1,y=node2,fill=bw)) + geom_tile()
g <- g + theme(axis.text.x = element_text(angle=90))
png(file="$map_bw")
print(g)
dev.off()
HERE

# Run the R script.
if [[ verbose == 0 ]] 
then
  Rscript $rscript 2>&1 > /dev/null
else
  Rscript $rscript
fi
