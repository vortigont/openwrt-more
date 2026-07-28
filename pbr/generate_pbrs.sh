#!/usr/bin/env bash

# location variables
tmpdir='/tmp/pbrs'
src="./"
dst="lists"


itdoginfo_intrus='https://raw.githubusercontent.com/itdoginfo/allow-domains/refs/heads/main/Russia/outside-raw.lst'
itdoginfo_extrus='https://raw.githubusercontent.com/itdoginfo/allow-domains/refs/heads/main/Russia/inside-raw.lst'

intrus_include='intrus_domains_inc.txt'
intrus_exclude='intrus_domains_exc.txt'
extrus_include='extrus_domains_inc.txt'
extrus_exclude='extrus_domains_exc.txt'

pbr_table_intrus='pbr-intrus'
pbr_table_extrus='pbr-extrus'

# include local config variables overrides
[ -r .config ] && source .config
[ ! -e ${dst} ] && mkdir -p ${dst}
[ ! -e ${tmpdir} ] && mkdir -p ${tmpdir}

# check md5 sum for two files in arguments, returns 0 is md5 matches, 1 otherwise 
check_md5() {
    local f1="$1"
    local f2="$2"
    if [ -r ${f1} ] && [ -r ${f2} ] ; then
        #md5sum ${f1} ${f2}
        if [ "$(md5sum ${f1} | awk {'print $1'})" = "$(md5sum ${f2} | awk {'print $1'})" ] ; then
            return 0
        fi
    fi
    return 1
}

update_file() {
    local src_file="$1"
    cmp -s ${tmpdir}/$src_file ${dst}/$src_file || mv ${tmpdir}/$src_file ${dst}/
}

update_file_md5() {
    local src_file="$1"
    if ! check_md5 ${tmpdir}/$src_file ${dst}/$src_file; then
	mv ${tmpdir}/$src_file ${dst}/
    fi
}

curl -s ${itdoginfo_intrus} --output ${tmpdir}/intrus_raw
curl -s ${itdoginfo_extrus} --output ${tmpdir}/extrus_raw
# combine with local include lists
grep -vE '^#|^$' ${intrus_include} >> ${tmpdir}/intrus_raw
grep -vE '^#|^$' ${extrus_include} >> ${tmpdir}/extrus_raw
# exclude and sort
grep -vE '^#|^$' ${intrus_exclude} > ${tmpdir}/intrus_exclude
grep -vE '^#|^$' ${extrus_exclude} > ${tmpdir}/extrus_exclude
grep -vwF -f ${tmpdir}/intrus_exclude ${tmpdir}/intrus_raw | sort -u > ${tmpdir}/intrus_result
grep -vwF -f ${tmpdir}/extrus_exclude ${tmpdir}/extrus_raw | sort -u > ${tmpdir}/extrus_result

## Loop over local addon config files
for file in extrus_domains_inc_rt*.txt; do
    [ -e "$file" ] || continue
    grep -vE '^#|^$' ${file} | sort -u > ${tmpdir}/${file}
done


# generate dnsmasq conf files for intrus list
## IFS will remove all leading/trailing spaces!!!
while IFS= read -r line
do
  # generate nft list
  echo "nftset=/${line}/4#inet#fw4#${pbr_table_intrus}" >> ${tmpdir}/intrus_nft_dnsmasq.conf
  # generate ipset list
  echo "ipset=/${line}/${pbr_table_intrus}" >> ${tmpdir}/intrus_ipset_dnsmasq.conf
done < "${tmpdir}/intrus_result"

update_file "intrus_nft_dnsmasq.conf"
update_file "intrus_ipset_dnsmasq.conf"

# generate dnsmasq conf files for extrus list
## IFS will remove all leading/trailing spaces!!!
while IFS= read -r line
do
  # generate nft list
  echo "nftset=/${line}/4#inet#fw4#${pbr_table_extrus}" >> ${tmpdir}/extrus_nft_dnsmasq.conf
  # generate ipset list
  echo "ipset=/${line}/${pbr_table_extrus}" >> ${tmpdir}/extrus_ipset_dnsmasq.conf
done < "${tmpdir}/extrus_result"

update_file "extrus_nft_dnsmasq.conf"
update_file "extrus_ipset_dnsmasq.conf"



## Loop over local addon config files
for file in ${tmpdir}/extrus_domains_inc_rt*.txt; do
    [ -e "$file" ] || continue
    fname=`basename $file`
    item=${fname#extrus_domains_inc_}  	# remove prefix "extrus_domains_inc_"
    item=${item%.txt}      		# remove suffix ".txt"

    #echo "Process $file as item: $item"

    while IFS= read -r line
    do
    # generate nft list  extrus_nft_dnsmasq.conf
    echo "nftset=/${line}/4#inet#fw4#${pbr_table_extrus}" >> ${tmpdir}/${item}_extrus_nft_dnsmasq.conf
    # generate ipset list
    echo "ipset=/${line}/${pbr_table_extrus}" >> ${tmpdir}/${item}_extrus_ipset_dnsmasq.conf
    done < "${file}"

    update_file ${item}_extrus_nft_dnsmasq.conf
    update_file ${item}_extrus_ipset_dnsmasq.conf
done


rm -rf ${tmpdir}
