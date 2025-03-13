#!/usr/bin/env bash

# location variables
tmpdir="/tmp"
src="./"
dst="${tmpdir}/adhosts"

# include local config variables overrides
[ -r .config ] && source .config
[ ! -e ${dst} ] && mkdir -p ${dst}

curl -s https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts > ${tmpdir}/hosts.StevenBlack
# sources for hosts file
# https://github.com/StevenBlack/hosts
# https://discourse.pi-hole.net/t/how-do-i-block-ads-on-youtube/253/134

#make sure '127.0.0.1 localhost' be the first line in hosts (may affect android)
cat <<EOF >  ${dst}/hosts
# a combined hosts lists including default localhost entries
#
127.0.0.1 localhost
127.0.0.1 localhost.localdomain
::1 localhost
::1 ip6-localhost
::1 ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts
#
## Adv hosts
EOF

#echo "Clean comments and empty lines"
grep -vE '^#|^$'  ${src}/domains.my > ${tmpdir}/domains.my
grep -vE '^#|^$'  ${src}/whitelist.my > ${tmpdir}/whitelist.my

echo "combine all hosts and remove all whitelisted items"
cat  ${src}/hosts.* ${tmpdir}/hosts.StevenBlack | grep -vE '^#|^$' | tr -d '\15\32' | sort -u -k 2 | grep -vwF -f ${tmpdir}/whitelist.my > $tmpdir/hosts.combined

# save default items to a temp
#awk '{print $2}'  ${dst}/hosts > $tmpdir/hosts.default

# create two files:
#  ${dst}/hosts - a combined file with default items
#  ${dst}/hosts.adv - just adv items
echo "make combined lists"
echo "#all sorts of adv hosts combined, excluding default localhost entries" >  ${dst}/hosts.adv
# make a filter for default entries
grep -vE '^#|^$' ${dst}/hosts | awk '{print $2}' > $tmpdir/hosts.def_pattern
grep -vwF -f $tmpdir/hosts.def_pattern $tmpdir/hosts.combined | tee -a  ${dst}/hosts >>  ${dst}/hosts.adv
rm  $tmpdir/hosts.combined $tmpdir/hosts.def_pattern

# create windows compatible hosts
awk 'sub("$", "\r")'  ${dst}/hosts >  ${dst}/hosts.win

#generate ad domains list
#./dom_stat.pl  ${dst}/hosts.adv > ${tmpdir}/domains.ad
sort -u ${tmpdir}/domains.* > ${tmpdir}/domains.unique

# generate domains-wide block for dnsmasq
awk '{ print "server=/"$1"/"}' ${tmpdir}/domains.unique > ${dst}/blocked_domains.conf

# remove dnsmasq's domains-wide blocked hosts items
echo "make banned hosts"
echo "#banned hosts, excluding domain-wide bans via dnsmasq" >  ${dst}/hosts.ad
grep -vF -f ${tmpdir}/domains.unique  ${dst}/hosts.adv >>  ${dst}/hosts.ad

rm ${tmpdir}/domains.*
rm ${tmpdir}/whitelist.my
