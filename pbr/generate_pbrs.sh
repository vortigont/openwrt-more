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

# generate dnsmasq conf files for intrus list
## IFS will remove all leading/trailing spaces!!!
while IFS= read -r line
do
  # generate nft list
  echo "nftset=/${line}/4#inet#fw4#${pbr_table_intrus}" >> ${tmpdir}/intrus_nft_dnsmasq.conf
  # generate ipset list
  echo "ipset=/${line}/${pbr_table_intrus}" >> ${tmpdir}/intrus_ipset_dnsmasq.conf
done < "${tmpdir}/intrus_result"

if ! check_md5 ${tmpdir}/intrus_nft_dnsmasq.conf ${dst}/intrus_nft_dnsmasq.conf; then
    mv ${tmpdir}/intrus_nft_dnsmasq.conf ${dst}/intrus_nft_dnsmasq.conf
fi

if ! check_md5 ${tmpdir}/intrus_ipset_dnsmasq.conf ${dst}/intrus_ipset_dnsmasq.conf; then
    mv ${tmpdir}/intrus_ipset_dnsmasq.conf ${dst}/intrus_ipset_dnsmasq.conf
fi

# generate dnsmasq conf files for extrus list
## IFS will remove all leading/trailing spaces!!!
while IFS= read -r line
do
  # generate nft list
  echo "nftset=/${line}/4#inet#fw4#${pbr_table_extrus}" >> ${tmpdir}/extrus_nft_dnsmasq.conf
  # generate ipset list
  echo "ipset=/${line}/${pbr_table_extrus}" >> ${tmpdir}/extrus_ipset_dnsmasq.conf
done < "${tmpdir}/extrus_result"

if ! check_md5 ${tmpdir}/extrus_nft_dnsmasq.conf ${dst}/extrus_nft_dnsmasq.conf; then
    mv ${tmpdir}/extrus_nft_dnsmasq.conf ${dst}/extrus_nft_dnsmasq.conf
fi

if ! check_md5 ${tmpdir}/extrus_ipset_dnsmasq.conf ${dst}/extrus_ipset_dnsmasq.conf; then
    mv ${tmpdir}/extrus_ipset_dnsmasq.conf ${dst}/extrus_ipset_dnsmasq.conf
fi

rm ${tmpdir}/intrus_*
rm ${tmpdir}/extrus_*

#domains=`cat ${tmpdir}/intrus_raw | tr -s "\n" "/"`
#mydomains=`cat my_intrus_inc.txt | tr -s "\n" "/"`

#echo "nftset=/${mydomains}/4#inet#fw4#${pbr_table_intrus}" >> ${dst}/pbr_intrus_dnsmasq.conf



