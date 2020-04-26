#!/bin/sh

echo "=== init ==="
echo "builder;bb;user;system;elapsed;cpu;avgtest;avgdata;maxresident;inputs;outputs;major;minor;swaps" | tee table.time.init.csv
for i in */[123]*log; do
    builder=`dirname $i`
    task=`basename $i | sed 's/\.log//g'`
    # 37.60user 4.64system 2:52:19elapsed 0%CPU (0avgtext+0avgdata 28724maxresident)k
    u=`tail -n 2 $i | grep "user " | sed 's/user /;/g; s/system /;/g; s/elapsed /;/g; s/%CPU (/;/g; s/avgtext+/;/g; s/avgdata /;/g; s/maxresident)k//g'`
    # 52784inputs+6432outputs (1771major+17635minor)pagefaults 0swaps
    s=`tail -n 1 $i | grep "swaps$" | sed 's/inputs+/;/g; s/outputs (/;/g; s/major+/;/g; s/minor)pagefaults /;/g; s/swaps//g'`
    # threadripper-3970x-64gb::37.60;4.64;2:52:19;0;0;0;28724:52784;6432;1771;17635;0
    echo "$builder;$task;$u;$s"
done | tee -a table.time.init.csv
echo
echo "=== builds ==="
echo "builder;bb;user;system;elapsed;cpu;avgtest;avgdata;maxresident;inputs;outputs;major;minor;swaps" | tee table.time.build.csv
for i in */[4567]*log; do
    builder=`dirname $i`
    bb=`basename $i | sed 's/?-build-//g; s/-bb-threads.log//g; s/all-cores.log/all/g'`

    # 37.60user 4.64system 2:52:19elapsed 0%CPU (0avgtext+0avgdata 28724maxresident)k
    u=`tail -n 2 $i | grep "user " | sed 's/user /;/g; s/system /;/g; s/elapsed /;/g; s/%CPU (/;/g; s/avgtext+/;/g; s/avgdata /;/g; s/maxresident)k//g'`
    # 52784inputs+6432outputs (1771major+17635minor)pagefaults 0swaps
    s=`tail -n 1 $i | grep "swaps$" | sed 's/inputs+/;/g; s/outputs (/;/g; s/major+/;/g; s/minor)pagefaults /;/g; s/swaps//g'`
    # threadripper-3970x-64gb::37.60;4.64;2:52:19;0;0;0;28724:52784;6432;1771;17635;0
    echo "$builder;$bb;$u;$s"
done | tee -a table.time.build.csv

steps="build-test fetch builds"
for step in $steps; do
    echo
    echo "=== top20 $step ==="
    echo "builder;step;task;time" | tee table.top20.${step}.csv
    builds="*/*${step}*.top20"
    [ $step = "builds" ] && builds="*/[4567]*build*.top20"

    tasks=`grep -v '/build_stats$' ${builds} | sed 's/^.* seconds //g' | sort -u`
    for t in $tasks; do
        # m4-native-1.4.18-r0/do_configure
        task=`echo $t | sed "s#-[^-/]*-[^-/]*/#.#g"`
        for i in ${builds}; do
            builder=`dirname $i`
            build=`basename $i | sed 's/\.top20//g; s/?-build-//g; s/-threads//g; s/all-cores/all/g'`
            # 0.95 seconds m4-native-1.4.18-r0/do_fetch
            time=`grep " $t$" $i | sed 's/ seconds .*$//g'`
            [ -z "$time" ] && time="---"
            echo "$builder;$build;$task;$time"
        done
    done | tee -a table.top20.${step}.csv
    task=Total
    for i in ${builds}; do
        builder=`dirname $i`
        build=`basename $i | sed 's/\.top20//g; s/?-build-//g; s/-threads//g; s/all-cores/all/g'`
        # 24.39 seconds  20200213014740/build_stats
        time=`grep "/build_stats$" $i | sed 's/ seconds .*$//g'`
        [ -z "$time" ] && time="---"
        echo "$builder;$build;$task;$time"
    done | tee -a table.top20.${step}.csv
done

# Builds in columns
steps="build-test fetch builds"
for step in $steps; do
    echo
    echo "=== top20 $step ==="
{
    builds="*/*${step}*.top20"
    [ $step = "builds" ] && builds="*/[4567]*build*.top20"

    tasks=`grep -v '/build_stats$' ${builds} | sed 's/^.* seconds //g' | sort -u`

    echo -n "task"
    for i in ${builds}; do
        builder=`dirname $i`
        echo -n ";$builder"
    done
    echo
    echo -n "sec"
    for i in ${builds}; do
        build=`basename $i | sed 's/\.top20//g; s/?-build-//g; s/-threads//g; s/all-cores/all/g'`
        echo -n ";$build"
    done

    echo
    for t in $tasks; do
        # m4-native-1.4.18-r0/do_configure
        task=`echo $t | sed "s#-[^-/]*-[^-/]*/#.#g"`
        echo -n "$task"
        for i in ${builds}; do
            builder=`dirname $i`
            build=`basename $i | sed 's/\.top20//g; s/?-build-//g; s/-threads//g; s/all-cores/all/g'`
            # 0.95 seconds m4-native-1.4.18-r0/do_fetch
            time=`grep " $t$" $i | sed 's/ seconds .*$//g'`
            [ -z "$time" ] && time="---"
            echo -n ";$time"
        done
        echo
    done
    task=Total
    echo -n "$task"
    for i in ${builds}; do
        builder=`dirname $i`
        build=`basename $i | sed 's/\.top20//g; s/?-build-//g; s/-threads//g; s/all-cores/all/g'`
        # 24.39 seconds  20200213014740/build_stats
        time=`grep "/build_stats$" $i | sed 's/ seconds .*$//g'`
        [ -z "$time" ] && time="---"
        echo -n ";$time"
    done
} | tee table.top20s.${step}.csv
done

echo "=== MBW ==="
echo "builder;method;MiB/s" | tee table.mbw.csv
grep AVG */mbw.txt */mbw*/mbw.txt | sed 's#/mbw.txt:AVG.*Method: #;#g; s# *Elapsed:.*Copy: #;#g; s#\t *##g; s# MiB/s##g' | tee -a table.mbw.csv

echo "=== MBW Sysbench ==="
echo "builder;threads;block size;total size;ops/s;MiB/s;min;avg;max;95th;sum" | tee table.mbw.sysbench.csv
for i in */sysbench-* */*/sysbench-*; do
    th=`grep "Number of threads: " $i | sed 's/.*Number of threads: //g'`
    bs=`grep "block size: " $i | sed 's/.*block size: //g'`
    ts=`grep "total size: " $i | sed 's/.*total size: //g'`
    ops=`grep "operations: " $i | sed 's/.* operations: .* (\(.*\) per second)/\1/g'`
    tr=`grep "transferred " $i | sed 's/.* transferred (\(.*\) MiB\/sec)/\1/g'`
    lmin=`grep "min:" $i | sed 's/.*min: *//g'`
    lavg=`grep "avg:" $i | sed 's/.*avg: *//g'`
    lmax=`grep "max:" $i | sed 's/.*max: *//g'`
    l95th=`grep "percentile:" $i | sed 's/.*percentile: *//g'`
    lsum=`grep "sum:" $i | sed 's/.*sum: *//g'`
    echo "$i;$th;$bs;$ts;$ops;$tr;$lmin;$lavg;$lmax;$l95th;$lsum"
done | tee -a table.mbw.sysbench.csv
