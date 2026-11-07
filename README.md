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

# Precompiled packages (ipk)

https://dl.eko.one.pl/packages/opkg/all/

# Precompiled packages (apk)

https://dl.eko.one.pl/packages/apk/noarch/

# The project is used in
- [3ginfo](https://eko.one.pl/?p=openwrt-3ginfo) - [src](https://github.com/obsy/packages/tree/master/3ginfo)
- [easyconfig](https://eko.one.pl/?p=easyconfig) - [src](https://github.com/obsy/easyconfig)
- [luci-app-modemdata](https://eko.one.pl/forum/viewtopic.php?id=24829) - [src](https://github.com/4IceG/luci-app-modemdata)

## Shared AT transport and Quectel reporting

When QModem's `at-daemon` is present, AT collection uses `tom_modem -u`
and the same per-port flock as QModem instead of opening a competing serial
reader. `tom_modem` must be available in that setup. A daemon discovery or
transport error fails closed: it does not retry directly against an owned port.
Without the daemon, collection uses direct `tom_modem` when installed, otherwise
`sms_tool`. The backend package depends on `flock`.

The Quectel USB `2c7c:0800` collector reads identity fields as complete AT
transactions, filters echoes/unsolicited responses, and validates numeric SIM
and modem identifiers. Its LTE/NR handler recognizes connected NSA measurements
even when registration AcT remains LTE (7), while rejecting placeholder NR rows.
This changes reporting, not modem band locks or network attachment behavior.

### Regression tests

Run from this repository's root (Python 3, BusyBox and flock required):

```sh
python3 tests/test-modemdata-transport.py
python3 tests/test-modemdata-nsa.py
```

Tests exercise the production source with simulated AT replies; no modem or
private router capture is required. `MODEMDATA_SOURCE_ROOT` can optionally point
to another checkout for source-import verification. CI runs the same tests.
