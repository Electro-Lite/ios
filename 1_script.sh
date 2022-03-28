#!bin/sh
export POSIXLY_CORRECT=yes
export LC_NUMERIC=en_US.UTF-8

print_help(){
  echo "COMMAND:"
  echo "        list-tick"
  echo "        profit"
  echo "        pos"
  echo "        last-price"
  echo "        hist-ord"
  echo "        graph-pos"
  echo "FILTER: "
  echo "        -a DATETIME"
  echo "        -b DATETIME"
  echo "        -t TICKER"
  echo "        -w WIDTH"
}

COMMAND=""
LOG_FILES=""
FILTERARR=()
TICARR=()
latch=0
WIDTH=1000

while [ "$#" -gt 0 ];
 do
 case $1 in
 #### FILES ####
  *.gz)
    LOG_FILES="${LOG_FILES} $(gzip  -d  -c  $1 )"
    shift
    ;;
  *.log)
    LOG_FILES="${LOG_FILES} $(cat $1)"
    shift
    ;;
  #### FILTERS ####
  -a)
    FILTERARR+=("-a")
    AFTER=$2
    shift
    shift
    ;;
  -b)
    FILTERARR+=("-b")
    BEFORE=$2
    shift
    shift
    ;;
  -t)
    FILTERARR+=("-t")
    TICARR+=($2)
    shift
    shift
    ;;
  -w)
    FILTERARR+=("-w")
    TMP=$2
    WIDTH=1
    for (( i = 0; i < TMP; i++ )); do
        WIDTH="${WIDTH}0"
    done
    TMP=""
    shift
    shift
    ;;
#### COMMANDS ####
  -h)
    print_help
    ;;
  --help)
    print_help
    ;;

  list-tick)
    COMMAND=$1
    shift
    ;;
  profit)
    COMMAND=$1
    shift
    ;;
  pos)
    COMMAND=$1
    shift
    ;;
  last-price)
    COMMAND=$1
    shift
    ;;
  hist-ord)
    COMMAND=$1
    shift
    ;;
  graph-pos)
    COMMAND=$1
    shift
    ;;
  *)
    shift
    ;;
 esac
done

#### FILTER SECTION ####

for CFIL in "${FILTERARR[@]}"
 do
   case $CFIL in
   -a)
     LOG_FILES=$(echo "$LOG_FILES" | awk -F ';' -v datetime="$AFTER" '{if(datetime < $1 ) print}')
     ;;
   -b)
     LOG_FILES=$(echo "$LOG_FILES" | awk -F ';' -v datetime="$BEFORE" '{if(datetime > $1 ) print}')
     ;;
   -t)
     if [ $latch -ne 1 ]; then
      for CTIC in "${TICARR[@]}"
       do
         CTIC="${CTIC};"
         TMP="${TMP} $( echo "$LOG_FILES" | grep $CTIC )"
       done
      LOG_FILES=$TMP
      TMP=""
      latch=1
     fi
     ;;
   esac
 done

#### COMMAND SECTION ####

if [ "$COMMAND" = "list-tick" ]; then
  LOG_FILES=$(echo "$LOG_FILES" | awk -F ';' '{print $2}' | sort -u )
  echo "$LOG_FILES"

elif [ "$COMMAND" = "profit" ]; then
  echo "$(echo "$LOG_FILES" | awk -F ';' '{$3 == "sell" ? ( total += $4 * $6 ) : ( total-= $4 * $6 )} END {print total}')"

elif [ "$COMMAND" = "pos" ]; then
  UTIC=$(echo "$LOG_FILES" | awk -F ';' '{print $2}' | sort -u )
  UTIC=$(echo "$UTIC" | awk -F '\n' -v x="\"" '{print x$1x}' ORS=' ')
  UTIC="UTICAR=("${UTIC}")"
  eval "$UTIC"
  Result=""
  for CTIC in "${UTICAR[@]}"
   do
     TMP=$(echo "$LOG_FILES" | grep $CTIC | awk -F ';' -v x="$CTIC" '{$3 == "sell" ? ( total += $4 * $6 ) : ( total-= $4 * $6 )} END {printf "%-9s : %11.2f",x,total}')
     Result="${Result} "$'\n'" ${TMP}"
   done
  echo "$Result"

elif [ $COMMAND = "last-price" ]; then
  LOG_FILES=$(echo "$LOG_FILES"  | sort -r ) #Warning
  UTIC=$(echo "$LOG_FILES" | awk -F ';' '{print $2}' | sort -u )
  UTIC=$(echo "$UTIC" | awk -F '\n' -v x="\"" '{print x$1x}' ORS=' ')
  UTIC="UTICAR=("${UTIC}")"
  eval "$UTIC"
  Result=""
  for CTIC in "${UTICAR[@]}"
   do
     TMP=$(echo "$LOG_FILES" | grep $CTIC | awk -F ';' -v x="$CTIC" '{printf "%-9s : %11.2f",x,$4}{exit}')
     Result="${Result} "$'\n'" ${TMP}"
   done
  echo "$Result"

elif [ $COMMAND = "hist-ord" ]; then
  LOG_FILES=$(echo "$LOG_FILES"  | sort -r ) #Warning
  UTIC=$(echo "$LOG_FILES" | awk -F ';' '{print $2}' | sort -u )
  UTIC=$(echo "$UTIC" | awk -F '\n' -v x="\"" '{print x$1x}' ORS=' ')
  UTIC="UTICAR=("${UTIC}")"
  eval "$UTIC"
  Result=""
  for CTIC in "${UTICAR[@]}"
   do
     CTIC="${CTIC};"
     TMP=$(echo "$LOG_FILES" | grep -c $CTIC | awk -v x="$CTIC" '{printf "%-9s : ",x} {i = 0; do { printf "#"; ++i} while (i < $1 ) } {exit}')
     TMP="${TMP}"
     Result="${Result} "$'\n'" ${TMP}"
   done
  echo "$Result"

elif [ $COMMAND = "graph-pos" ]; then
  UTIC=$(echo "$LOG_FILES" | awk -F ';' '{print $2}' | sort -u )
  UTIC=$(echo "$UTIC" | awk -F '\n' -v x="\"" '{print x$1x}' ORS=' ')
  UTIC="UTICAR=("${UTIC}")"
  eval "$UTIC"
  Result=""
  for CTIC in "${UTICAR[@]}"
   do
     CTIC="${CTIC};"
     TMP=$(echo "$LOG_FILES" | grep $CTIC | awk -F ';' -v WIDTH="$WIDTH" -v x="$CTIC" -v sign="#" '{$3 == "sell" ? ( total += $4 * $6 ) : ( total-= $4 * $6 )} END {printf "%-9s : %f",x,total;i = 1;if (total<0) {sign="!";total=total * -1}; while (i < total/1000 ) { ++i; printf "%c",sign} }')
     Result="${Result} "$'\n'" ${TMP}"
   done
  echo "$Result"

fi
