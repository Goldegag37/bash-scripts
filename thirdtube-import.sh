#!/bin/bash

## csv parseing:
# Source: https://www.cyberciti.biz/faq/unix-linux-bash-read-comma-separated-cvsfile/
# Purpose: Read Comma Separated CSV File
# Author: Vivek Gite under GPL v2.0+

## other stuff:
# probably stack overflow, ai or i wrote it.

select r in


echo -n '{"version":"0","channels":[' > subscription.json
echo "Please input the csv filename."
read INPUT

OLDIFS=$IFS
IFS=','
[ ! -f $INPUT ] && { echo "$INPUT file not found"; exit 99; }
while read id url name
do
	echo "id : $id"
	echo "url : $url"
	echo "name : $name"

echo -n "{\"id\":\"$id\",\"url\":\"$url\", \"icon_url\":\"https://yt3.googleusercontent.com/584JjRp5QMuKbyduM_2k5RlXFqHJtQ0qLIPZpwbUjMJmgzZngHcam5JMuZQxyzGMV5ljwJRl0Q=s176-c-k-c0x00ffffff-no-rj\",\"name\":\"$name\",\"subscriber_count_str\":\"click to fix\"}," >> subscription.json

done < $INPUT
IFS=$OLDIFS
json=$(cat subscription.json)
echo ${json%,} > subscription.json

echo ']}' >> subscription.json
