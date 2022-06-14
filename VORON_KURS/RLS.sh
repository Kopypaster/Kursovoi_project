#!/bin/bash

#РЛС проверяет направление полета БР по 2-м засечкам, если движение БР направлено в зону ответственности СПРО, выдавать соответствующую информацию на КП,
#также выдавать информацию обо всех замеченных целях в зоне обзора.
#Не допускать повторную выдачу одинаковой информации.

#Сразу введём параметры РЛС , на 10^3, метры
x=11000000
y=8000000
a=90
#Днепр
view_rad=120
range = 3000000

#Нужно почистить директории 
cleaner=`ps -eF | grep rls1 | tr -s [:blank:] | cut -d ' ' -f 2 2>/dev/null` 2>/dev/null
Counter=0

for variable in $cleaner
do
	let Counter=$Counter+1
done

if [[ $Counter -gt 3 ]]
then
	echo "запуск не разрешен, скрипт уже выполяется"
	exit
fi

rm ./rls_idlog 2>/dev/null
rm ../../summary/rlssummary 2>/dev/null
rm ./rls_fulllog 2>/dev/null
rm ../../summary/otchet_RLS 2>/dev/null
rm ../../summary/RLS_det 2>/dev/null

x0=11000000 #м 
y0=8000000 #м
#Днепр
az=270    
ph=120     
d=3000000 

function InSproDirection()
{
	local Rpsro=1600000 #м

	local Xspro=3200000 #м 
	local Yspro=3700000 #м
	
	local Xtarget=$1
	local Ytarget=$2
	
	local VXtarget=$3
	local VYtarget=$4
	
	let xdir=-1*$Xtarget+$Xspro
	let ydir=-1*$Ytarget+$Yspro
	
	local phi=$(echo | awk " { x=atan2($ydir,$xdir)*180/3.141592653589; print x}")
	phi=(${phi/\,*})
	
	local phiV=$(echo | awk " { x=atan2($VYtarget,$VXtarget)*180/3.141592653589; print x}")
	phiV=(${phiV/\,*})
		
	if [[ "$phi" -lt "0" ]]
	then
		let phi=360+$phi
	fi

	if [[ "$phiV" -lt "0" ]]
	then
		let phiV=360+$phiV
	fi	
	
	let dist2=$xdir*$xdir+$ydir*$ydir
	
	echo $dist2 >> ./rls_fulllog 2>/dev/null
	
	theta=$(echo | awk " { x=$Rpsro/sqrt($dist2); y=atan2(x, sqrt(1-x*x))*180/3.141592653589; print y}")
	echo "thinking of theta before trunc= "$theta >> ./rls_fulllog 2>/dev/null
	theta=(${theta/\,*})
	echo "thinking of theta after trunc= "$theta >> ./rls_fulllog 2>/dev/null
	
	if [[ "$theta" = "-nan" ]]
	then
		echo "found tasty ananas" >> ./rls_fulllog 2>/dev/null
		theta=180
	fi
	
	let thetaMin=$phi-$theta
	let thetaMax=$phi+$theta
	
	echo "thetamax = "$thetaMin >> ./rls_fulllog 2>/dev/null
	echo "thetamin = "$thetaMax >> ./rls_fulllog 2>/dev/null
	
	check360=0
	check0=0
	if [[ "$thetaMax" -gt "360" ]]
	then
		check360=1
	fi

	if [[ "$thetaMin" -lt "0" ]]
	then
		check0=1
	fi
	
	echo $check360 >> ./rls_fulllog 2>/dev/null
	echo $check0 >> ./rls_fulllog 2>/dev/null
	
	if [[ $check360 -eq 0 && $check0 -eq 0 ]]
	then

		if [[ $phiV -gt $thetaMin && $phiV -lt $thetaMax ]]
		then
		
			echo "target in normal sector" >> ./rls_fulllog 2>/dev/null
		
			echo "targetInSproDir = true" >> ./rls_fulllog 2>/dev/null
			echo $phi >> ./rls_fulllog 2>/dev/null
			echo $phiV >> ./rls_fulllog 2>/dev/null
			return 1
		else
			echo "targetInSproDir = false" >> ./rls_fulllog 2>/dev/null
			echo $phi >> ./rls_fulllog 2>/dev/null
			echo $phiV >> ./rls_fulllog 2>/dev/null
			return 0
		fi
	else
		if [[ $check360 -eq 1 && $check0 -eq 0 ]]
		then
		
			echo "target in normal 360+sect" >> ./rls_fulllog 2>/dev/null
		
			let thetaMax360=$thetaMax-360
			echo $thetaMax360 >> ./rls_fulllog 2>/dev/null
			if [[ $phiV -gt $thetaMin || $phiV -lt $thetaMax360 ]]
			then
				echo "targetInSproDir = true" >> ./rls_fulllog 2>/dev/null
				echo "phi = "$phi >> ./rls_fulllog 2>/dev/null
				echo "phiV = "$phiV >> ./rls_fulllog 2>/dev/null
				echo "thetaMax360 = "$thetaMax360 >> ./rls_fulllog 2>/dev/null
				return 1
			else
				echo "targetInSproDir = true" >> ./rls_fulllog 2>/dev/null
				echo "phi = "$phi >> ./rls_fulllog 2>/dev/null
				echo "phiV = "$phiV >> ./rls_fulllog 2>/dev/null
				echo "thetaMax360 = "$thetaMax360 >> ./rls_fulllog 2>/dev/null
				return 0
			fi
		
		else
			if [[ $check360 -eq 0 && $check0 -eq 1 ]]
			then
			
				echo "target in normal 0-sect" >> ./rls_fulllog 2>/dev/null
			
				let thetaMin0=360+$thetaMin
				echo $thetaMin0 >> ./rls_fulllog 2>/dev/null
				if [[ $phiV -gt $thetaMin0 || $phiV -lt $thetaMax ]]
				then
					echo "targetInSproDir = true" >> ./rls_fulllog 2>/dev/null
					echo "phi = "$phi >> ./rls_fulllog 2>/dev/null
					echo "phiV = "$phiV >> ./rls_fulllog 2>/dev/null
					echo "phiMin0 = "$thetaMin0 >> ./rls_fulllog 2>/dev/null
					return 1
				else
					echo "targetInSproDir = true" >> ./rls_fulllog 2>/dev/null
					echo "phi = "$phi >> ./rls_fulllog 2>/dev/null
					echo "phiV = "$phiV >> ./rls_fulllog 2>/dev/null
					echo "phiMin0 = "$thetaMin0 >> ./rls_fulllog 2>/dev/null
					return 0
				fi
			fi
		fi
	fi
		
}


function InRlsZone()
{
	local X=$1
	local Y=$2
	local X0=$3
	local Y0=$4
	local R=$5
	local AZ=$6
	local PH=$7

	let dx=$X-$X0
	let dy=$Y-$Y0
	
	local r=$(echo "sqrt ( (($dx*$dx+$dy*$dy)) )" | bc -l)
	r=${r/\.*}

	if (( $r <= $R ))
	then
		local phi=$(echo | awk " { x=atan2($dy,$dx)*180/3.14; print x}")
		phi=(${phi/\,*})

	  	if [[ "$phi" -lt "0" ]]
	 	then
	   		let phi=360+$phi	   
		fi

		let phiMax=$AZ+PH/2
		let phiMin=$AZ-PH/2
			
		echo "angle = "$phi >> ./rls_fulllog 2>/dev/null
		echo "id = "$id >> ./rls_fulllog 2>/dev/null
		echo "phimax = "$phiMax >> ./rls_fulllog 2>/dev/null
		echo "phimin = "$phiMin >> ./rls_fulllog 2>/dev/null
			
 		if (( $phi <= $phiMax )) && (( $phi >= $phiMin ))
		then
			return 1
		fi
	fi

	return 0
}

unique_id=0
deadflag=0
targets_dir=/tmp/GenTargets/Targets/
i=0

while :
do
	touch ../../summary/RLS_det 2>/dev/null
	
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
		
		InRlsZone $x $y $x0 $y0 $d $az $ph
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
						echo "checkid = "$id >> ./rls_fulllog 2>/dev/null
						echo "thisid = "${targets[0+$((idx-1))*10]} >> ./rls_fulllog 2>/dev/null
						echo "isalive = "${targets[5+$((idx-1))*10]} >> ./rls_fulllog 2>/dev/null
						echo "isreported = "${targets[6+$((idx-1))*10]} >> ./rls_fulllog 2>/dev/null

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
											
							# if target is alive and we have not reported КП о нет, то сообщаем
							if [[ ${targets[5+$((idx-1))*10]} -eq 1 && ${targets[6+$((idx-1))*10]} -eq 0 && "$v2" != 0 ]]
							then
								echo "Обнаружена цель с ID = "$id" с координатами "$x" и "$y" и скоростями "$vx" и "$vy >>../../summary/rlssummary 2>/dev/null
								echo "`date +%s`:$id:$x:$y:0:-1" >> ../../summary/otchet_RLS 2>/dev/null
								targets[6+$((idx-1))*10]=1;
																	
								if [[ v2 -ge 64000000 && v2 -le 100000000 ]]
								then
								
									# это ББ от БР
									InSproDirection $x $y $vx $vy
									targetInSproDir=$?
									
									# это ББ от БР летит к СПРО
									echo "id = "$id >> ./rls_fulllog 2>/dev/null
									echo "targetInSproDir = "$targetInSproDir >> ./rls_fulllog 2>/dev/null
									if [[ $targetInSproDir -eq 1 ]]
									then
										echo "Цель ID = "$id" движется в зону действия СПРО" >> ../../summary/rlssummary 2>/dev/null
										echo "`date +%s`:$id:$x:$y:3:-1" >> ../../summary/otchet_RLS 2>/dev/null
									fi
									
								fi
							fi
						fi
						
						break
					fi
				
				done
				
				# после цикла по всем имеющимся целями так и не нашли новую цель
				if [[ $found -eq 0 ]]
				then
					deadflag=1
					unfound[0+$((unfound_count))*3]=$id;
					unfound[1+$((unfound_count))*3]=$x;
					unfound[2+$((unfound_count))*3]=$y;
					
					# увеличиваем счетчик новых целей
					$((unfound_count++)) 2>/dev/null
				fi
		
			fi
								
			if [[ $i -eq 0 ]]
			then
				targets[0+$((current_counter-1))*10]=$id;
				targets[1+$((current_counter-1))*10]=$x;
				targets[2+$((current_counter-1))*10]=$y;
				targets[3+$((current_counter-1))*10]=$vx;
				targets[4+$((current_counter-1))*10]=$vy;
				targets[5+$((current_counter-1))*10]=0; # флаг актуальности цели
				targets[6+$((current_counter-1))*10]=0; # флаг выдачи данных на КП
			fi

			$((unique_id++)) 2>/dev/null
			echo "$unique_id:$id" >> ./rls_idlog
				
			$((current_counter++)) 2>/dev/null
		fi

	done
	deadflag=0
	
	echo "unfound count = "$unfound_count >> ./rls_fulllog 2>/dev/null
	
	# после полной итерации считывания целей обрабатываем новые цели	
	for ((thiscount=1; thiscount<=unfound_count; thiscount++))
	do
		echo "unfound id# "$thiscount" = "${unfound[0+$((thiscount-1))*3]} >> ./rls_fulllog 2>/dev/null
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
			fi
					
		done
	
	done
	
	echo $i >> ./rls_idlog
	$((i++)) 2>/dev/null
		
	sleep 0.5

	echo "___" >> ./rls_fulllog 2>/dev/null
	echo "NEW i"$i >> ./rls_fulllog 2>/dev/null
	echo "___" >> ./rls_fulllog 2>/dev/null

done