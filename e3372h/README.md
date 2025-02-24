## Huawei E3372h scripts

Here is a set of OpenWRT scripts and files to provide transparent hot-plug switching
for Huawei E3372h modems running HiLink firmware into Gateway+NDIS (CDC_NCM) mode.

It gives superior performance, no double NAT-ing, full control for the modem and no need to chande default USB-composition.

More details could be found at [4PDA forum](https://4pda.ru/forum/index.php?showtopic=582284&view=findpost&p=100309827)

###Installation
Execute the following via router's CLI

    curl -sL https://api.github.com/repos/vortigont/openwrt-more/tarball | tar xzo -C /tmp/
    cd /tmp/vortigont-openwrt-more* && find ./ -name "*.md" -exec rm {} +
    cp -au ./e3372h/* /


### Configuration
An example of /etc/config/network with LTE interface configured for 4G modem
```
config interface 'LTE'
    option proto 'ncm'
    option apn 'internet'
    option device '/dev/ttyUSB2'
    option ifname 'wwan0'
    option delay '3'
    option auto '0'
    option disabled '0'
    option ttlfix '0'
```



Enable LTE autoconnect on router hot restart
    /etc/init.d/e3372h enable

