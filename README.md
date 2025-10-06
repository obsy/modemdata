# Detailed information about the cellular modem

Package designed for OpenWrt

## network

```
/usr/share/modemdata/network.sh <network section>
```

## product

via serial port
```
/usr/share/modemdata/product.sh <device>
```

via ModemManager
```
/usr/share/modemdata/product_modemmanager.sh <device>
```

## connection parameters

via serial port

```
/usr/share/modemdata/params.sh <device> [0|1 force PLMN from file]
```

via ModemManager
```
/usr/share/modemdata/params_modemmanager.sh <device> [0|1 force PLMN from file]
```

via QMI/MBIM
```
/usr/share/modemdata/params_qmi.sh <device> [0|1 force PLMN from file] [0|1 MBIM device]
```

# Precompiled packages for stable release

https://dl.eko.one.pl/packages/opkg/all/

# Precompiled packages for development snapshots

https://dl.eko.one.pl/packages/apk/all/

# The project is used in
- [3ginfo](https://eko.one.pl/?p=openwrt-3ginfo) - [src](https://github.com/obsy/packages/tree/master/3ginfo)
- [easyconfig](https://eko.one.pl/?p=easyconfig) - [src](https://github.com/obsy/easyconfig)
- [luci-app-modemdata](https://eko.one.pl/forum/viewtopic.php?id=24829) - [src](https://github.com/4IceG/luci-app-modemdata)
