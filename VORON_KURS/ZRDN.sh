#!/bin/bash

cleaner=`ps -eF | grep zrdn1 | tr -s [:blank:] | cut -d ' ' -f 2 2>/dev/null` 2>/dev/null
Counter=0

for variable in $cleaner
do
	let Counter=$Counter+1
done

if [[ $Counter -gt 3 ]]
then
	echo "Скрипт запущен"
	exit
fi

rm ./zrdn_idlog 2>/dev/null
rm ../../summary/zrdnsummary 2>/dev/null
rm ./zrdn_fulllog 2>/dev/null
rm ../../summary/otchet_ZRDN 2>/dev/null
rm ../../summary/ZRND_det 2>/dev/null


#Донецк
x0=3200000 #м 
y0=3000000 #м
ammo=20
d=600000 #м


function InZrdnRange()
{
	local X=$1
	local Y=$2
	local x0=$3
	local y0=$4
	local R=$5

	let dx=$X-$x0 2>/dev/null
	let dy=$Y-$y0 2>/dev/null
	
	local r=$(echo "sqrt ( (($dx*$dx+$dy*$dy)) )" | bc -l)
	r=${r/\.*}
	
	echo $id >> ./zrdn_fulllog 2>/dev/null
	echo $r1 >> ./zrdn_fulllog 2>/dev/null

	if [ "$r" -le "$R" 2>/dev/null ]
	then
		return 1
	fi
	return 0
}


unique_id=0
deadflag=0
targets_dir=/tmp/GenTargets/Targets/
destroy_dir=/tmp/GenTargets/Destroy/
i=0
fired_count=0

while :
do

	touch ../../summary/ZRND_det 2>/dev/null

	for ((idx=1; idx<=30; idx++))
	do
		targets[5+$((idx-1))*10]=0
	done
	
	unfound_count=0
	current_counter=1
	
	
	for file in `ls $targets_dir -t 2>/dev/null | head -30`
	do
		x=`cat $targets_dir$file | tr -d 'X''Y' | tr ',' ':' | cut -d : -f1 2>/dev/null`
		y=`cat $targets_dir$file | tr -d 'X''Y' | tr ',' ':' | cut -d : -f2 2>/dev/null`
		id=${file:12:6}
		
		targetInZone=0	

		InZrdnRange $x $y $x0 $y0 $d
		targetInZone=$?

		if [[ $targetInZone -eq 1 ]]
		then
		
			if [[ $i -ge 1 ]]
			then
				found=0 # еще не нашли эту цель
				for ((idx=1; idx<=30; idx++))
				do
					
					if [[ $deadflag -eq 1 ]]
					then
						echo "checkid = "$id >> ./zrdn_fulllog 2>/dev/null
						echo "thisid = "${targets[0+$((idx-1))*10]} >> ./zrdn_fulllog 2>/dev/null
						echo "isalive = "${targets[5+$((idx-1))*10]} >> ./zrdn_fulllog 2>/dev/null
						echo "isreported = "${targets[6+$((idx-1))*10]} >> ./zrdn_fulllog 2>/dev/null

					fi
									
					if [[ "${targets[0+$((idx-1))*10]}" == "$id" ]]
					then
		
						found=1
						
						if [[ ${targets[5+$((idx-1))*10]} -eq 0 ]]
						then
						
							#found=1
							oldx=${targets[1+$((idx-1))*10]}
							oldy=${targets[2+$((idx-1))*10]}
							targets[1+$((idx-1))*10]=$x
							targets[2+$((idx-1))*10]=$y							
							let vx=x-oldx
							let vy=y-oldy
										
							if [[ "$vx" != "0" ]]
							then
								targets[3+$((idx-1))*10]=$vx
							fi
							
							if [[ "$vy" != "0" ]]
							then
								targets[4+$((idx-1))*10]=$vy
							fi
							
							let v2=vx*vx+vy*vy
															
							#alive flag
							targets[5+$((idx-1))*10]=1;
							
							echo "id = "$id >> ./zrdn_fulllog
							echo "v2 = "$v2 >> ./zrdn_fulllog
											
							# if this target is over-class target
							if [[ $v2 -ge 2500 && $v2 -le 1000000 ]]
							then
								echo "v2 is ok" >> ./zrdn_fulllog
								
								
								# if target is alive and we have not reported КП о нет, то сообщаем о наличии по 6 флагу
								if [[ ${targets[5+$((idx-1))*10]} -eq 1 && ${targets[6+$((idx-1))*10]} -eq 0 && "$v2" != 0 ]]
								then
									targetClass="Самолет"
									if [[ $v2 -gt 62500 ]]
									then
										targetClass="Крылатая ракета"
									fi
									echo ${targets[6+$((idx-1))*10]} >> ./zrdn_fulllog
									echo "Обнаружена цель - "$targetClass" с ID = "$id" с координатами "$x" и "$y" и скоростями "$vx" и "$vy >>../../summary/zrdnsummary 2>/dev/null
									echo "found new target id = "$id"no more warnings about this should be..." >> ./zrdn_fulllog
									echo "`date +%s`:$id:$x:$y:0:-1" >> ../../summary/otchet_ZRDN 2>/dev/null
									targets[6+$((idx-1))*10]=1;
									
								fi
								
								echo "ТУТ НАЧИНАЕМ ПИСАТЬ ПРО ОБРАБОТКУ ВЫСТРЕЛА! ! ! !" >> ./zrdn_fulllog 2>/dev/null
								echo "это кд по итерациям для цели "$id" кд = ${targets[7+$((idx-1))*10]}" >> ./zrdn_fulllog 2>/dev/null
								
								# 7 это задержка после выстрела на анализ / уничтожения-промаха по цели
								if [[ ${targets[7+$((idx-1))*10]} != 0 ]]
								then	
									let targets[7+$((idx-1))*10]=${targets[7+$((idx-1))*10]}-1
								fi
								
								echo "текущая задержка равна = "${targets[7+$((idx-1))*10]} >> ./zrdn_fulllog 2>/dev/null
								
								# делаем выстрел по этой цели, если не делали его только что (до 2х итераций до этой)
								if [[ ${targets[5+$((idx-1))*10]} -eq 1 && ${targets[7+$((idx-1))*10]} -eq 0 && "$v2" != 0 ]]
								then
									echo "ammo = "$ammo >> ./zrdn_fulllog
									if [[ $ammo -gt 0 ]]
									then
										touch $destroy_dir$id
										let ammo=ammo-1
										echo "Произведен выстрел по цели - "$targetClass" с ID = "$id" с координатами "$x" и "$y" и скоростями "$vx" и "$vy >>../../summary/zrdnsummary 2>/dev/null
										echo "`date +%s`:$id:$x:$y:1:$ammo" >> ../../summary/otchet_ZRDN 2>/dev/null
										echo "firing on "$id >> ./zrdn_fulllog 2>/dev/null
										
										targets[7+$((idx-1))*10]=4
										fired[0+$((fired_count))*5]=$id
										fired[1+$((fired_count))*5]=4 
										fired[2+$((fired_count))*5]=0 # результаты стрельбы
										fired[3+$((fired_count))*5]=$x
										fired[4+$((fired_count))*5]=$y
										
										
										echo "сохраненные данные"  >> ./zrdn_fulllog 2>/dev/null
										echo "id = "${fired[0+$((fired_count))*5]} >> ./zrdn_fulllog 2>/dev/null
										echo "fired[1] кд еще одно = "${fired[1+$((fired_count))*5]} >> ./zrdn_fulllog 2>/dev/null
										
										$((fired_count++)) 2>/dev/null
									else
										echo "Не могу произвести выстрел по цели - "$targetClass" с ID = "$id" с координатами "$x" и "$y" и скоростями "$vx" и "$vy >>../../summary/zrdnsummary 2>/dev/null
										echo "cant fire no ammo on "$id >> ./zrdn_fulllog 2>/dev/null
										echo "`date +%s`:$id:$x:$y:2:$ammo" >> ../../summary/otchet_ZRDN 2>/dev/null
									fi
								fi
							fi
						fi
						
						break
					fi
				
				done
				
				echo "id = "$id >> ./zrdn_fulllog 2>/dev/null
				echo "found = "$found >> ./zrdn_fulllog 2>/dev/null

				# после цикла по всем имеющимся целями так и не нашли новую цель
				if [[ $found -eq 0 ]]
				then
					deadflag=1
					unfound[0+$((unfound_count))*3]=$id
					unfound[1+$((unfound_count))*3]=$x
					unfound[2+$((unfound_count))*3]=$y
					
					# увеличиваем счетчик новых целей
					$((unfound_count++)) 2>/dev/null
				fi
		
			fi
								
			if [[ $i -eq 0 ]]
			then
				targets[0+$((current_counter-1))*10]=$id
				targets[1+$((current_counter-1))*10]=$x
				targets[2+$((current_counter-1))*10]=$y
				targets[3+$((current_counter-1))*10]=$vx
				targets[4+$((current_counter-1))*10]=$vy
				targets[5+$((current_counter-1))*10]=0 # флаг актуальности цели
				targets[6+$((current_counter-1))*10]=0 # флаг выдачи данных на КП
				targets[7+$((current_counter-1))*10]=0 # флаг выдачи информации о стрельбе на КП
			fi

			$((unique_id++)) 2>/dev/null
			echo "$unique_id:$id" >> ./zrdn_idlog
				
			$((current_counter++)) 2>/dev/null
		fi

	done
	deadflag=0
	
	echo "unfound count = "$unfound_count >> ./zrdn_fulllog 2>/dev/null
	
	# после полной итерации считывания целей обрабатываем новые цели	
	for ((thiscount=1; thiscount<=unfound_count; thiscount++))
	do
		echo "unfound id# "$thiscount" = "${unfound[0+$((thiscount-1))*3]} >> ./zrdn_fulllog 2>/dev/null
		# берем новую цель и записываем ее на место мертвой в массиве
		for ((idx=1; idx<=30; idx++))
		do
		
			if [[ ${targets[5+$((idx-1))*10]} -eq 0 && $i -gt 1 ]]
			then
				
				targets[0+$((idx-1))*10]=${unfound[0+$((thiscount-1))*3]}
				targets[1+$((idx-1))*10]=${unfound[1+$((thiscount-1))*3]}
				targets[2+$((idx-1))*10]=${unfound[2+$((thiscount-1))*3]}
				targets[5+$((idx-1))*10]=1
				targets[6+$((idx-1))*10]=0
				targets[7+$((idx-1))*10]=0;
			fi
					
		done
	
	done
	
	for ((thiscount=1; thiscount<=fired_count; thiscount++))
	do
		#уменьшаем кулдаун
		if [[ ${fired[1+$((thiscount-1))*5]} -eq 0 ]]
		then
			# об этой цели не сообщали == 0
			if [[ ${fired[2+$((thiscount-1))*5]} -eq 0 ]]
			then
				#больше не учитываем эту цель
				fired[2+$((thiscount-1))*5]=1
				
				# гипотеза, что мы поразили, т.к. вероятность поражения большая
				flag_shot=1
				
				fired_id=${fired[0+$((thiscount-1))*5]}
				
				echo "Проверяем в этом списке текущих целей ту, по которой стреляли:"$fired_id >> ./zrdn_fulllog 2>/dev/null
				
				#если в списках не значится значит уничтожли
				for ((idx=1; idx<=30; idx++))
				do
					echo "тестриуем "$idx ": id = "${targets[0+$((idx-1))*10]} >> ./zrdn_fulllog 2>/dev/null
					
					if [[ "${targets[0+$((idx-1))*10]}" == "$fired_id" && ${targets[5+$((idx-1))*10]} -eq 1 ]]
					then
						flag_shot=0
					fi
				done
				
				echo "flagshot = "$flag_shot >> ./zrdn_fulllog 2>/dev/null
				
				if [[ $flag_shot -eq 1 ]]
				then
					echo "Цель поражена ID = "$fired_id >> ../../summary/zrdnsummary 2>/dev/null
					echo "`date +%s`:$fired_id:${fired[3+$((thiscount-1))*5]}:${fired[4+$((thiscount-1))*5]}:4:-1" >> ../../summary/otchet_ZRDN 2>/dev/null
				else
					echo "Промах по цели ID = "$fired_id >>../../summary/zrdnsummary 2>/dev/null
					echo "`date +%s`:$fired_id:${fired[3+$((thiscount-1))*5]}:${fired[4+$((thiscount-1))*5]}:5:-1" >> ../../summary/otchet_ZRDN 2>/dev/null
				fi
				
				
			fi
		else
			let fired[1+$((thiscount-1))*5]=${fired[1+$((thiscount-1))*5]}-1
		fi
	
	done
	
	
	
	
	
	
	
	
	
	
	
	
	
	echo $i >> ./zrdn_idlog
	$((i++)) 2>/dev/null
	
	sleep 0.5

	echo "___" >> ./zrdn_fulllog 2>/dev/null
	echo "NEW i"$i >> ./zrdn_fulllog 2>/dev/null
	echo "___" >> ./zrdn_fulllog 2>/dev/null

done
