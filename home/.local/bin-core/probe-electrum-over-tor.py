#!/usr/bin/env python3
import os, sys, ssl, socket, time, json

TOR = os.environ.get("TOR_SOCKS", "127.0.0.1:9050")
if ":" not in TOR: TOR += ":9050"
TORH, TORP = TOR.rsplit(":",1)
TORP = int(TORP)

def tor_connect(host, port, timeout=6.0):
    s=socket.socket(); s.settimeout(timeout); s.connect((TORH,TORP))
    s.sendall(b"\x05\x01\x00")
    if s.recv(2)!=b"\x05\x00": raise RuntimeError("SOCKS5 auth failed")
    hb=host.encode(); pkt=b"\x05\x01\x00\x03"+bytes([len(hb)])+hb+int(port).to_bytes(2,"big")
    s.sendall(pkt)
    rep=s.recv(4)
    if len(rep)<4 or rep[1]!=0x00: raise RuntimeError("SOCKS5 connect failed")
    atyp=s.recv(1)
    if atyp==b"\x01": s.recv(4)
    elif atyp==b"\x03": l=s.recv(1)[0]; s.recv(l)
    elif atyp==b"\x04": s.recv(16)
    else: raise RuntimeError("SOCKS5 atyp bad")
    s.recv(2)
    return s

def ping(addr):
    host,port,proto = addr.split(":")
    raw=tor_connect(host,int(port),timeout=8.0)
    ctx=ssl.create_default_context(); ctx.check_hostname=False; ctx.verify_mode=ssl.CERT_NONE
    conn=ctx.wrap_socket(raw, server_hostname=host); conn.settimeout(8.0)
    t0=time.perf_counter()
    conn.sendall((json.dumps({"id":0,"method":"server.version","params":["retoswap","1.4"]})+"\n").encode())
    buf=b""
    while b"\n" not in buf:
        b=conn.recv(4096)
        if not b: break
        buf+=b
        if len(buf)>65536: break
    ms=round((time.perf_counter()-t0)*1000.0,2)
    return ms if buf else None

def main():
    addrs = sys.argv[1:] or []
    if not addrs:
        print("usage: probe-electrum-over-tor.py host:port:s [...]")
        sys.exit(2)
    print(f"[probe] TOR={TORH}:{TORP}")
    for a in addrs:
        try:
            t=ping(a)
            if t is not None:
                print(f"[probe] OK {a} {t}ms")
            else:
                print(f"[probe] FAIL {a}")
        except Exception as e:
            print(f"[probe] ERR  {a} {e}")
if __name__ == "__main__":
    main()
