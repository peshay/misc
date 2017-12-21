#!/bin/bash
db=zway
probe=temperature
maxval=50

devices=$(influx -database "$db" -execute "show series" | grep "probe=$probe" | cut -f 1 -d ",")
for device in $devices; do
    times=$(influx -database "$db" -execute "select level from \"$device\" where level > $maxval;" -format "csv" | grep -v "name,time,level" | cut -f 2 -d ",");
    for time in $times; do
        influx -database "$db" -execute "delete from \"$device\" where time = $time;";
    done;
done
