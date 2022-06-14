#!/bin/bash

if [ -z $1 ] ; then
echo "Usage: ./tbdb.sh DBFILE.txt select [-n] [-b] N1,N2,.. [where M=TEXT] [line M]"
exit;
fi

db=$1
shift;
if [ $1 == "-n" ]; then
	#include line numbers
	NUM=1
	shift;
fi

if [ $1 == "-b" ]; then
	#base64
	BASE64=1
	shift;
fi

if [ $1 == "select" ]; then
	shift;
	lines=`cat "$db"`
	IFS=$','
	ciN=0
	for ci in $1; do
		((ciN++))
		qcol[$ciN]=$ci
	done

	shift;

	#do query
	ONLYLINE=0
	if [ $1 == "line" ]; then
		shift;
		ONLYLINE=$1;
		shift;
	fi

	WHERELINE=0
	if [ $1 == "where" ]; then
		WHERELINE=1
		shift;
		IFS=$','
		wiN=0
		for wi in $1; do
			((wiN++))
			WhereList1[wiN]="`echo "$wi" | tr "=" "\n" | sed "1 ! d"`"
			WhereList2[wiN]="`echo "$wi" | tr "=" "\n" | sed "2 ! d"`"
		done
		
		shift;
	fi

	IFS=$'\n'
	nline=0
	stop=0
	for line in $lines; do
		((nline++))
		IFS=$'\t'
		LINEOK=0
		ncol=0
		for xm in $line; do
			if [ $BASE64 -eq 1 ]; then
				x="`echo "$xm" | base64 -d`"
			else
				x=$xm
			fi

			if [ $stop -eq 1 ]; then
				break;
			fi
			((ncol++))

			coltrue=0

			for qic in "${qcol[@]}"; do
				if [ $ncol -eq $qic ]; then
					coltrue=1
				fi
			done

			if [ $coltrue -eq 1 ]; then
				if [ $WHERELINE -eq 1 ]; then
					WLXN=0
					wlx2=""
					for wlx1 in "${WhereList1[@]}"; do
						((WLXN++))
						if [ $ncol -eq $wlx1 ]; then
							wlx2=${WhereList2[$WLXN]}
							break;
						fi
					done
					if [ $x == $wlx2 ]; then
						IFS=$'\t'
						COLXN=0
						for xtxy in $line; do
							if [ $BASE64 -eq 1 ]; then
								xtx="`echo "$xtxy" | base64 -d`"
							else
								xtx="$xtxy"
							fi
							((COLXN++))
							coltrue=0
							for qic in "${qcol[@]}"; do
								if [ $COLXN -eq $qic ]; then
									coltrue=1
								fi
							done
							if [ $coltrue -eq 1 ]; then
								if [ $NUM -eq 1 ]; then
									if [ -z $res ]; then
										res="$nline: "$xtx;
									else
										res=${res}$'\n'"$nline: "$xtx;
									fi
								else
									if [ -z $res ]; then
										res=$xtx;
									else
										res=${res}$'\n'$xtx;
									fi
								fi
							fi
						done
						break;
					fi
				fi
			fi
			

			if [ $ONLYLINE -ne 0 ] ; then
				coltrue=0
				for qic in "${qcol[@]}"; do
					if [ $ncol -eq $qic ]; then
						coltrue=1
					fi
				done
				if [ $coltrue -eq 1 ]; then
					if [ $ONLYLINE -eq $nline ]; then
						if [ $NUM -eq 1 ]; then
							if [ -z $res ]; then
								res="$nline: "$x;
							else
								res=${res}$'\n'"$nline: "$x;
							fi
						else	
							if [ -z $res ]; then
								res=$x;
							else
								res=${res}$'\n'$x;
							fi
						fi
					fi
					if [ $ONLYLINE -eq 0 ]; then
						if [ $NUM -eq 1 ]; then
							tmp="$nline: $x"
						else	
							tmp="$x"
						fi

						if [ -z $res ]; then
							res=$tmp
						else
							res=${res}$'\n'${tmp}
						fi
					fi
				fi
			fi
		done
	done
	echo "$res"
fi

if [ $1 == "insert" ]; then
	shift;
	$res=""
	for ix in $@; do
		if [ $BASE64 -eq 1 ]; then
			i="`echo "$ix" | base64`"
		else
			i="$ix"
		fi
		if [ -z $res ]; then
			res=$i
		else
			res=${res}$'\t'${i}
		fi
	done
	echo "$res" >> $db
fi

if [ $1 == "delete" ]; then
	shift;
	if [ $1 == "line" ]; then
		shift;
		cat -n $db | grep "^ *${1}" | sed "s/^ *${1}\t//" > /tmp/dbdelete
		diff $db /tmp/dbdelete | grep "^<" | sed "s/< //" > /tmp/dbdelete2
		cp /tmp/dbdelete2 $db
	fi
fi