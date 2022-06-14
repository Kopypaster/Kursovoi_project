#!/bin/bash

BASEDIR=$(dirname $(realpath "$0"))
echo $BASEDIR
./StopSystems.sh 1>/dev/null


echo "Запуск генератора целей..."
sleep 2

cd $BASEDIR 1>/dev/null &
GTpid=$!
echo "Запущен генератор целей с pid = "$GTpid
sleep 0.5

cd $BASEDIR/RLS.sh &
RLS1pid=$!
echo "Запущена РЛС c pid = "$RLS1pid
sleep 0.5

cd $BASEDIR/SPRO.sh &
SPROpid=$!
echo "Запущена СПРО c pid = "$SPROpid
sleep 0.5

cd $BASEDIR/ZRDN.sh &
ZRDN1pid=$!
echo "Запущен ЗРДН 1 c pid = "$ZRDN1pid
sleep 0.5

cd $BASEDIR/POST.sh &
KPpid=$!
echo "Запущен КП с pid = "$KPpid
sleep 0.5


echo "Для остановки всех систем воспользуйтесь ./StopSystems.sh"
sleep 0.5



