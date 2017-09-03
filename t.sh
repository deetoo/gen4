#!/bin/bash
#
cp /tmp/ntp.conf /tmp/ntp.conf.BAK

sed -i 's/xxx.xxx.xxx.xxx/147.75.16.13/g' /tmp/ntp.conf
sed -i 's/aaa.aaa.aaa.aaa/147.75.16.14/g' /tmp/ntp.conf
ntpdate -u 147.75.16.13
service ntpd restart

