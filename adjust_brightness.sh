#!/bin/bash


## Original, horribly written script taken from:
## http://wiki.laptop.org/go/Xfce_keybindings#Adjust_screen_brightness_buttons
## This is floating around the interwebs, should send this improved version out 

# The first argument is whether to increase the brightness (+) or
# decrease the brightness (-).
# The second argument is optional and indicates the step size when
# increasing or decreasing the brightness. The default is 1.

bright_file="/sys/class/backlight/intel_backlight/brightness"
mbright_file="/sys/class/backlight/intel_backlight/max_brightness"

[ $# -eq 0 ] && exit 1

direction="$1"
step="${2:-1}"

brightness="`head -n 1 $bright_file`"
max_brightness="`head -n 1 $mbright_file`"

declare -i brightness
declare -i step
declare -i new_brightness

if [ "-" == "$direction" ]; then
    new_brightness=$brightness-$step 
else
    new_brightness=$brightness+$step
fi

echo "Switching brightness from $brightness to $new_brightness out of $max_brightness"

[ $brightness -ge 0 ] && [ $brightness -le $max_brightness ] && { echo $new_brightness > $bright_file; }