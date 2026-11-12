@echo off
start "TempleOS HolyCoin VM" "C:\Program Files\qemu\qemu-system-x86_64.exe" -machine pc -m 512M -smp 2 -drive file=templeos.qcow2,if=ide,index=0,media=disk -serial tcp:127.0.0.1:4444,server,nowait -rtc base=localtime
