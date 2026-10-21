#!/usr/bin/env python3
"""Tiny App Store Connect API client (ES256 JWT via openssl, no deps).

The private key is read from the login keychain (generic password,
service "App Store Connect API", account = key ID, value = base64 of the .p8)
and only ever handed to openssl through a pipe — it never touches the disk.

usage:
  asc.py METHOD PATH [JSON_BODY_FILE]   call the API, print status and JSON
  asc.py keyfile -- CMD ...             run CMD with $ASC_KEY_PATH pointing to a
                                        temporary copy of the key (for xcodebuild),
                                        deleted again afterwards
"""
import base64, contextlib, json, os, subprocess, sys, tempfile, time, urllib.request, urllib.error

KEY_ID = "WZNGQ5P94T"
ISSUER = "69a6de93-83a7-47e3-e053-5b8c7c11a4d1"
KEYCHAIN_SERVICE = "App Store Connect API"

_key = None

def private_key():
    global _key
    if _key is None:
        out = subprocess.run(["security", "find-generic-password", "-a", KEY_ID, "-s", KEYCHAIN_SERVICE, "-w"],
                             capture_output=True, text=True, check=True).stdout.strip()
        _key = base64.b64decode(out)
    return _key

def b64(b): return base64.urlsafe_b64encode(b).rstrip(b"=")

def der_to_raw(der):
    # SEQUENCE { INTEGER r, INTEGER s } -> r||s (32 bytes each)
    assert der[0] == 0x30
    i = 2 if der[1] < 0x80 else 3
    out = b""
    for _ in range(2):
        assert der[i] == 0x02
        n = der[i + 1]
        v = der[i + 2:i + 2 + n].lstrip(b"\x00")
        out += v.rjust(32, b"\x00")
        i += 2 + n
    return out

def sign(msg):
    # key goes to openssl via an extra pipe (fd 3), the message via stdin
    r, w = os.pipe()
    proc = subprocess.Popen(["openssl", "dgst", "-sha256", "-sign", f"/dev/fd/{r}"],
                            stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, pass_fds=(r,))
    os.close(r)
    with os.fdopen(w, "wb") as pipe:
        pipe.write(private_key())
    der, err = proc.communicate(msg)
    if proc.returncode != 0:
        raise RuntimeError(err.decode())
    return der

def token():
    now = int(time.time())
    head = b64(json.dumps({"alg": "ES256", "kid": KEY_ID, "typ": "JWT"}).encode())
    body = b64(json.dumps({"iss": ISSUER, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"}).encode())
    msg = head + b"." + body
    return (msg + b"." + b64(der_to_raw(sign(msg)))).decode()

def call(method, path, body=None):
    url = path if path.startswith("http") else "https://api.appstoreconnect.apple.com" + path
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method, headers={
        "Authorization": "Bearer " + token(), "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req) as r:
            raw = r.read()
            return r.status, (json.loads(raw) if raw else None)
    except urllib.error.HTTPError as e:
        raw = e.read()
        return e.code, (json.loads(raw) if raw else None)

@contextlib.contextmanager
def key_file():
    """Temporary AuthKey_<id>.p8 (0600, private dir) for tools that need a path."""
    with tempfile.TemporaryDirectory(prefix="asc-") as d:
        path = os.path.join(d, f"AuthKey_{KEY_ID}.p8")
        fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        with os.fdopen(fd, "wb") as f:
            f.write(private_key())
        yield path

if __name__ == "__main__":
    if sys.argv[1] == "keyfile":
        cmd = sys.argv[sys.argv.index("--") + 1:]
        with key_file() as path:
            env = dict(os.environ, ASC_KEY_PATH=path, ASC_KEY_ID=KEY_ID, ASC_ISSUER_ID=ISSUER)
            sys.exit(subprocess.run(cmd, env=env).returncode)
    method, path = sys.argv[1], sys.argv[2]
    body = json.load(open(sys.argv[3])) if len(sys.argv) > 3 else None
    status, res = call(method, path, body)
    print(status)
    print(json.dumps(res, indent=1, ensure_ascii=False))
