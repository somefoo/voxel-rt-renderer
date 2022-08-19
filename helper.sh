#!/bin/bash

echo "Starting auto-clicker..."
while true; do
  watch -n 0.1 -d -t -g ls -lR --full-time ${1} | sha1sum
  echo [RUN] $(date)
  eval "$(xdotool getmouselocation --shell)"
  xdotool windowactivate $(xdotool search --name "Voxel-RT-Viewer")
  xdotool mousemove --window $(xdotool search --name "Voxel-RT-Viewer") 40 30
  xdotool click 1 
  xdotool windowactivate $WINDOW 
  xdotool mousemove --screen $SCREEN $X $Y
done
