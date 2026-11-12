import socket, sys, time
from pathlib import Path

raw = Path(sys.argv[1]).read_bytes().replace(b"\r\n", b"\n")
n = len(raw)
assert n < 65536, "File exceeds 64 KB header limit"

s = None
for _ in range(30):
    try:
        s = socket.create_connection(("127.0.0.1", 4444), timeout=2)
        break
    except OSError:
        time.sleep(0.5)

if s is None:
    raise RuntimeError("Could not connect to 127.0.0.1:4444. Run .\\vm.bat first!")

with s:
    s.settimeout(None)
    s.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
    print(f"[push.py] Ready to send {sys.argv[1]} ({n} bytes). Run Pull(...) in TempleOS...")
    while True:
        ch = s.recv(1)
        if not ch:
            raise ConnectionError("QEMU closed the serial socket.")
        if ch == b"R":
            break
    payload = bytes([n & 0xFF, (n >> 8) & 0xFF]) + raw
    total = len(payload)
    for idx, b in enumerate(payload, 1):
        s.sendall(bytes([b]))
        if s.recv(1) != b"\x06":
            raise RuntimeError("UART ACK mismatch")
        if idx % 512 == 0 or idx == total:
            print(f"\r[push.py] Transmitting over 0x3F8: {idx}/{total} bytes ({idx*100//total}%)", end="", flush=True)
    print("\n[push.py] Transfer complete!")
