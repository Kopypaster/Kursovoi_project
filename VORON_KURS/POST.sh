#!/bin/bash
# Прежде нужно почистить директорию
# Так чистить будем всегда
cleaner=`ps -eF | grep kp.sh | tr -s [:blank:] | cut -d ' ' -f 2 2>/dev/null` 2>/dev/null
Counter=0

for variable in $cleaner
do
	let Counter=$Counter+1
done

if [[ $Counter -gt 3 ]]
then
	echo "Обрати внимание, скрипт запущен. Нужен StopSystem"
	exit
fi

rm ./post_log 2>/dev/null 
mkdir ./summary/ 2>/dev/null

systems[1+$((1-1))*5]="РЛС"
systems[2+$((1-1))*5]="./summary/otchet_RLS"
systems[3+$((1-1))*5]="./summary/RLS_det"
systems[4+$((1-1))*5]=0 

systems[1+$((2-1))*5]="СПРО"
systems[2+$((2-1))*5]="./summary/otchet_post"
systems[3+$((2-1))*5]="./summary/SPRO_det"
systems[4+$((2-1))*5]=0

systems[1+$((3-1))*5]="ЗРДН"
systems[2+$((3-1))*5]="./summary/otchet_ZRDN"
systems[3+$((3-1))*5]="./summary/ZRND_det"
systems[4+$((3-1))*5]=0


idx_max=3;

# Может осуществлять такие действия. Действовать будем от перезарядки
actions[0]=" обнаружила цель "
actions[1]=" произвела выстрел по цели "
actions[2]=" не может стрелять по цели "
actions[3]=" цель движется в зону СПРО "
actions[4]=" поразила цель "
actions[5]=" промахнулась при стрельбе по цели "



echo "Запуск в `date +%d.%m\ %T`" >> ./post_log 2>/dev/null


i=0

while :
do
	for ((idx=1; idx<=idx_max; idx++))
	do
		checkthis=$(($i%50))
		if [[ $checkthis -eq 0 ]]
		then
			rm ${systems[3+$((idx-1))*5]} 2>/dev/null
			fileNotRemoved=$?
				# ожила             и              была мертва
			if [[ $fileNotRemoved -eq 0 && systems[4+$((idx-1))*5] -eq 0 ]]
			then
				echo ${systems[1+$((idx-1))*5]} " работает исправно" >> ./post_log 2>/dev/null
				systems[4+$((idx-1))*5]=1
			else
			
				# умерла             и              была жива
				if [[ $fileNotRemoved -eq 1 && systems[4+$(($idx-1))*5] -eq 1 ]]
				then
					echo ${systems[1+$((idx-1))*5]} " не работает" >> ./post_log 2>/dev/null
					systems[4+$((idx-1))*5]=0
				fi
			fi
		fi
		
		list=`cat ${systems[2+$((idx-1))*5]} 2>/dev/null`
		rm ${systems[2+$((idx-1))*5]} 2>/dev/null
		
		for message in $list
		do
			timestamp=`echo $message | cut -d : -f 1`
			id=`echo $message | cut -d : -f 2`
			x=`echo $message | cut -d : -f 3`
			y=`echo $message | cut -d : -f 4`
			action=`echo $message | cut -d : -f 5` # 0 stands for detection, 1 stands for firing, 2 stands for lack of ammo
			ammo=`echo $message | cut -d : -f 6` # ammo
			
			time=`date -d @$timestamp`

			
			if [[ "$ammo" -eq "-1" ]]
			then
				echo $time" "${systems[1+$((idx-1))*5]}${actions[$action]}"id = "$id" c координатами x = "$x" y = "$y >> ./post_log 2>/dev/null
			else
				echo $time" "${systems[1+$((idx-1))*5]}${actions[$action]}"id = "$id" c координатами x = "$x" y = "$y" Осталось снарядов = "$ammo >> ./post_log 2>/dev/null
			fi
		done
		
		
		
		i=$(($i+1))
	done
	
	sleep 0.1
done
