#!/bin/sh
##ffalarms##

ALSASTATE=%s
REPEAT=%d

AMIXER_PID=
ORIG_ALSASTATE=`mktemp /tmp/$0.XXXXXX`
DISPLAY=:0

COPY=
for NAME in `ls x*.ffalarms.* | sed s/^x//`; do
   ps -C "$NAME" > /dev/null && cp "/tmp/$NAME."* "$ORIG_ALSASTATE" \
       && COPY=1 && break
done
[ -n "$COPY" ] || alsactl -f "$ORIG_ALSASTATE" store

SS_TIMEOUT=$(expr "$(xset q -display $DISPLAY)" : ".*timeout:[ ]*\([0-9]\+\)")
if [ -z "$SS_TIMEOUT" ]; then
    SS_TIMEOUT=0
fi

quit() {
        kill "$AMIXER_PID" $!
        wait
        alsactl -f "$ORIG_ALSASTATE" restore
        if [ "$SS_TIMEOUT" -gt 0 ]; then
            xset -display $DISPLAY s "$SS_TIMEOUT"
        fi
        rm -f "x$0.$$" "$ORIG_ALSASTATE"
        exit
}
trap quit TERM

mv "$0" "x$0.$$"

PIDS=`ps -C ffalarms --no-heading --format "pid"` && \
    for PID in $PIDS; do kill -USR1 $PID && break; done || \
    { DISPLAY=$DISPLAY ffalarms --puzzle & }

xset -display $DISPLAY s off
xset -display $DISPLAY s reset

alsactl -f "$ALSASTATE" restore
amixer --quiet sset PCM,0 150
for x in `seq 150 255`; do echo sset PCM,0 $x || break; sleep 1; done \
    | amixer --stdin --quiet &
AMIXER_PID=$!

i=0
while [ $i -lt $REPEAT ]; do
    %s &
    wait $!
    i=$((i+1));
done

quit