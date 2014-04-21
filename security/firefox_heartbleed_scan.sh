#!/bin/bash


## Firefox places.sqlite scraping taken from here:
## https://totalrecall.wordpress.com/2008/09/03/automating-export-of-firefox-3-bookmarks-and-history-from-command-linecron/

### Parameters:

## How long to wait between queries to LastPass checker. Be nice and wait more than two seconds between:
num_seconds=2

### Step 1: create list of visited websites:

rm -f moz_places.html

sqlite3 "$HOME/tmp/places.sqlite" << EOF
.dump html
.output moz_places.html
select url,title from moz_places;
EOF


### Step 2: Create priority list for scans, based on frequency:

rm -f freq_sort_domain_list.txt

awk -F'/' '/^https/ {print $3}' moz_places.html | \
    sort | uniq -c | sort -n | tac > freq_sort_domain_list.txt


### Step 3: Use LastPass checker to see status:

rm -f report.html report.txt

echo "<html><body>" > report.html

for domain in `awk '{ print $2} ' freq_sort_domain_list.txt`
do

    freq=`awk -v domain="$domain" '$2 == domain { print $1 }' freq_sort_domain_list.txt`

    wget "https://lastpass.com/heartbleed/?h=$domain" -O test.html

    echo "Domain: $domain<br>" >> report.html
    echo "Frequency: $freq<br>" >> report.html

    egrep 'Site\:|SSL Certificate' test.html >> report.html
 
    echo "<hr>" >> report.html

    rm -f test.html

    sleep $num_seconds

done

echo "</body></html>" >> report.html
