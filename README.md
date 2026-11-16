<div align="center">

```text
                            |                            
                        ====+====                        
                            |                            
                            |                            
                  .=========+=========.                  
                 /   THE HOLY TEMPLE   \                 
             ====+=====================+====             
               | |   H O L Y C O I N   | |               
               |J|  RING-0 x SHA-256d  |B|               
               | |  REDSEA x 0x3F8 IO  | |               
             ====+=====================+====             
           [ JACHIN ]   640 x 480   [  BOAZ  ]           
```

# H O L Y C O I N

**Pure 64-Bit HolyC Bitcoin Cryptographic Engine, 2009 Genesis Verifier, Ring-0 PoW Miner & `0x3F8` Hardware UART Transceiver Inside 100% Vanilla TempleOS v5.03**

![OS](https://img.shields.io/badge/Sanctuary-Vanilla_TempleOS_v5.03-0000AA?style=for-the-badge)
![Language](https://img.shields.io/badge/Tongue-100%25_HolyC-AA00AA?style=for-the-badge)
![Privilege](https://img.shields.io/badge/Privilege-x86__64_Ring--0-008800?style=for-the-badge)
![UART](https://img.shields.io/badge/Bridge-0x3F8_16550_UART-AA5500?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-333333?style=for-the-badge)

![HolyCoin Sanctuary Terminal in Vanilla TempleOS](demo_v1.png)

</div>

> *"The RedSea has allocation bitmap for clus and all files are stored contiguously. You can't grow files."* ? **Terry A. Davis**, `:/Doc/Welcome.DD`

## Architecture

- **`HOLYCOIN.HC` (Stage 1  Offline Sanctuary Engine):** Pure HolyC FIPS 180-4 `SHA-256` & Bitcoin `SHA-256d`, Satoshi's 2009 Genesis Block verifier (`nonce = 2083236893`), Ring-0 PoW miner, deterministic `god.words[]` Oracle Seal, and contiguous RedSea (`B:/HOLYCOIN.BIN`) persistence.
- **`HOLYUART.HC` (Stage 2 `0x3F8` 16550 UART Block Driver):** Direct Ring-0 `InU8(0x3F8)` / `OutU8(0x3F8)` hardware serial transceiver with 84-byte `"HC01"` sliding-window frame recovery for zero-driver P2P header sync.
- **`Pull.HC` & `push.py`:** 23-line lockstep `0x3F8` source loader for beaming `.HC` files into live QEMU sessions.

## Verified Deterministic Chain Vectors

| Height | Block Role | `nBits` | Winning Nonce | `SHA-256d` Block Hash (Big-Endian Display) |
| :--- | :--- | :--- | :--- | :--- |
| `#00` | 2009 Bitcoin Genesis | `0x1d00ffff` | `2083236893` | `000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f` |
| `#01` | Genesis Child | `0x1f0fffff` | `1677` | `0005c971a430d82d7b4a267480020ddda93f0d6624846c690606444478ef0804` |
| `#02` | HolyCoin PoW | `0x1f0fffff` | `3269` | `00058166a8499bc29bd56d7962a9a254d44382bc1bb6a3bd7aa298e880975737` |
| `#03` | HolyCoin PoW | `0x1f0fffff` | `2364` | `00053e8355151e35839e655bb1be8eb27308eca30324d3a8e59ebaeca93b0ced` |
| `#04` | Persistent Reload +1 | `0x1f0fffff` | `433` | `000223697d55a59f792a4a68498a5dc6b5e617d8ab0279c16013fa6fde1de353` |

## Quick Start

```bash
vm.bat
python push.py HOLYCOIN.HC
```

Inside TempleOS (`C:/Home`):
```c
#include "Pull.HC";
Pull("C:/Home/HOLYCOIN.HC");
#include "HOLYCOIN.HC";
```

## License
MIT License. Vanilla TempleOS v5.03 is Public Domain software by Terry A. Davis.
