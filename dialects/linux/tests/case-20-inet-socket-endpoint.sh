#!/bin/sh

name=$(basename $0 .sh)
lsof=$1
report=$2

if ! [ $(id -u) = 0 ]; then
    echo "root privileged is needed to run $(basename $0. sh)" >> $report
    exit 2
fi

nc -l -4 127.0.0.1 10000 > /dev/null < /dev/zero &
server=$!
sleep 1
nc -4 -s 127.0.0.2 -p 9999 127.0.0.1 10000 < /dev/zero  > /dev/null &
client=$!

sleep 1

killBoth()
{
    kill -9 $1
    sleep 1
    kill -9 $2
} 2> /dev/null > /dev/null

fclient=/tmp/${name}-client-$$
$lsof -M -n -E -P -p $client > $fclient
if ! cat $fclient | grep -q "TCP 127.0.0.2:9999->127.0.0.1:10000 $server,nc,[0-9]\+u (ESTABLISHED)"; then
    echo "failed in client side" >> $report
    cat $fclient >> $report
    killBoth $client $server
    exit 1
fi

fserver=/tmp/${name}-server-$$
$lsof -M -n -E -P -p $server > $fserver
if ! cat $fserver | grep -q "TCP 127.0.0.1:10000->127.0.0.2:9999\+ $client,nc,[0-9]\+u (ESTABLISHED)"; then
    echo "failed in server side" >> $report
    cat $fserver >> $report
    killBoth $client $server
    exit 1
fi

killBoth $client $server

exit 0
