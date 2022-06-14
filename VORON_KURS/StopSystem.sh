#!/bin/bash

massive[0]="GenTargets"
massive[1]="RLS"
massive[2]="SPRO"
massive[3]="ZRDN"
massive[4]="POST"

size=4

for ((idx=0; idx<=size; idx++))
do

	cleaner=`ps -eF | grep ${massive[$idx]} | tr -s [:blank:] | cut -d ' ' -f 2 2>/dev/null` 2>/dev/null
	kill_sum=0
	for variable in $cleaner
	do
		kill $variable	2>/dev/null
		let kill_sum=kill_sum+1-$?
	done

	# т.к. grep сам умирает после своего выполнения, его kill всегда возвращает 1
	if [[ $kill_sum -gt 0 ]]
	then
		echo "${massive[$idx]}.sh остановлен"
	else
		echo "${massive[$idx]}.sh не остановлен или не был запущен"
	fi

	sleep 0.5
	
done

sleep 3
exit
