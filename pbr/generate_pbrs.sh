#!/usr/bin/env bash

# location variables
tmpdir='/tmp'
src="./"
dst="lists"


itdoginfo_intrus='https://raw.githubusercontent.com/itdoginfo/allow-domains/refs/heads/main/Russia/outside-raw.lst'
itdoginfo_extrus='https://raw.githubusercontent.com/itdoginfo/allow-domains/refs/heads/main/Russia/inside-raw.lst'
#itdoginfo_intrus_ipset='https://raw.githubusercontent.com/itdoginfo/allow-domains/refs/heads/main/Russia/outside-dnsmasq-ipset.lst'
#itdoginfo_intrus_nft='https://raw.githubusercontent.com/itdoginfo/allow-domains/refs/heads/main/Russia/outside-dnsmasq-nfset.lst'

intrus_include='intrus_domains_inc.txt'
intrus_exclude='intrus_domains_exc.txt'
extrus_include='extrus_domains_inc.txt'
extrus_exclude='extrus_domains_exc.txt'
extrus_rt='extrus_domains_rt.txt'
extrus_eva='extrus_domains_eva.txt'

pbr_table_intrus='pbr-intrus'
pbr_table_extrus='pbr-extrus'

# include local config variables overrides
[ -r .config ] && source .config
[ ! -e ${dst} ] && mkdir -p ${dst}

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
    if ! check_md5 ${tmpdir}/$src_file ${dst}/$src_file; then
	mv ${tmpdir}/$src_file ${dst}/
    fi
}

curl -s ${itdoginfo_intrus} --output ${tmpdir}/intrus_raw
curl -s ${itdoginfo_extrus} --output ${tmpdir}/extrus_raw
# combine various lists
grep -vE '^#|^$' ${intrus_include} >> ${tmpdir}/intrus_raw
grep -vE '^#|^$' ${extrus_include} >> ${tmpdir}/extrus_raw
# exclude and sort
grep -vE '^#|^$' ${intrus_exclude} > ${tmpdir}/intrus_exclude
grep -vE '^#|^$' ${extrus_exclude} > ${tmpdir}/extrus_exclude
grep -vwF -f ${tmpdir}/intrus_exclude ${tmpdir}/intrus_raw | sort -u > ${tmpdir}/intrus_result
grep -vwF -f ${tmpdir}/extrus_exclude ${tmpdir}/extrus_raw | sort -u > ${tmpdir}/extrus_result
# RT special
grep -vE '^#|^$' ${extrus_rt} > ${tmpdir}/${extrus_rt}
grep -vE '^#|^$' ${extrus_eva} > ${tmpdir}/${extrus_eva}

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


# generate dnsmasq conf files for extrus RT list
while IFS= read -r line
do
  # generate nft list
  echo "nftset=/${line}/4#inet#fw4#${pbr_table_extrus}" >> ${tmpdir}/extrus_rt_nft_dnsmasq.conf
  # generate ipset list
  echo "ipset=/${line}/${pbr_table_extrus}" >> ${tmpdir}/extrus_rt_ipset_dnsmasq.conf
done < "${tmpdir}/${extrus_rt}"

update_file "extrus_rt_nft_dnsmasq.conf"
update_file "extrus_rt_ipset_dnsmasq.conf"


# generate dnsmasq conf files for extrus eva list
while IFS= read -r line
do
  # generate nft list
  echo "nftset=/${line}/4#inet#fw4#${pbr_table_extrus}" >> ${tmpdir}/extrus_eva_nft_dnsmasq.conf
  # generate ipset list
  echo "ipset=/${line}/${pbr_table_extrus}" >> ${tmpdir}/extrus_eva_ipset_dnsmasq.conf
done < "${tmpdir}/${extrus_eva}"

update_file "extrus_eva_nft_dnsmasq.conf"
update_file "extrus_eva_ipset_dnsmasq.conf"


rm ${tmpdir}/intrus_*
rm ${tmpdir}/extrus_*
