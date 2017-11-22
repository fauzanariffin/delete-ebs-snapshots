#!/bin/sh

# Determine whether the OS is Linux or OSX based
if [ uname == "Linux" ]; then
    DATETOCOMPARE=$(date -v-30d +%s) #OSX
else
    DATETOCOMPARE=$(date --date="30 days ago" +%s) #Linux
fi

date > SNAP_TO_KEEP.txt
date > SNAP_TO_DELETE.txt

echo "Collecting snapshot information"

while read az; do
  echo "this is az "$az
                while read owner; do
                echo "this is owner "$owner
            aws ec2 describe-snapshots --region $az --owner-ids $owner --output json > listofsnaps.txt
            cat listofsnaps.txt | egrep "StartTime|SnapshotId" | awk -F'"' '{print $4}'  | awk 'NR%2{printf "%s, ",$0;next;}1' > listofsnaps.txt_tmp
            echo "listofsnaps for " $az "and owner" $owner "is ready"
                            while read snap
                            do
                            echo "working on snap " $snap
                            raw_date=`echo $snap | cut -d, -f1`
                            snap_date=`gdate -d $raw_date +%s`
                            echo "Snap date is: " $snap_date
                            echo "Snap to compare is: " $DATETOCOMPARE
                                      if [ $DATETOCOMPARE -gt $snap_date ]
                                      then
                                         echo $snap | cut -d, -f2 >> SNAP_TO_DELETE.txt
                                         snapToDelete=`echo $snap | cut -d, -f2`
                                         echo "Deleting Snapshot: " $snapToDelete
                                         aws ec2 delete-snapshot --region $az --snapshot-id $snapToDelete
                                         echo "aws ec2 delete-snapshot --region" $az "--snapshot-id" $snapToDelete
                                      else
                                         echo $snap | cut -d, -f2 >> SNAP_TO_KEEP.txt
                                      fi
                            done < listofsnaps.txt_tmp
              done <owner-list.txt
done <az-list.txt
