# AMNA1

Source IBM i dari library `AMNA1` di PUB400 (`185.113.5.134`, SSH port 2222), disusun untuk build dengan Bob (`makei`).

| Folder      | Source file asal | Isi            |
|-------------|------------------|----------------|
| `qddssrc/`  | `QDDSSRC`        | DDS PF/LF/DSPF |

## Tools (`tools/`)
Password dibaca dari env `IBMI_PWD`, jangan disimpan di repo. `jt400.jar` tidak di-commit
(download: `curl -fsSL -o tools/jt400.jar https://repo1.maven.org/maven2/net/sf/jt400/jt400/20.0.7/jt400-20.0.7.jar`).

```sh
# Export ulang semua member source dari library ke repo
IBMI_PWD=... java -cp tools/jt400.jar tools/Export.java 185.113.5.134 amna AMNA1 .

# Kirim file ke server (IFS /home/AMNA/amna1), tanpa compile
IBMI_PWD=... java -cp tools/jt400.jar tools/Push.java 185.113.5.134 amna /home/AMNA/amna1 $(git ls-files)

# Push + compile (*.pf, *.dspf, *.rpgle, *.sqlrpgle, *.clle) — source disalin ke member (folder = source file,
# mis. qrpglesrc/x.rpgle -> AMNA1/QRPGLESRC(X)) lalu compile dari member. Kredensial dari .env
tools/deploy.sh qrpglesrc/hallo.rpgle

# Jalankan CL command
IBMI_PWD=... java -cp tools/jt400.jar tools/Cl.java 185.113.5.134 amna "CALL AMNA1/HALLO"

# Jalankan query SQL
IBMI_PWD=... java -cp tools/jt400.jar tools/Sql.java 185.113.5.134 amna "SELECT * FROM AMNA1.\"USER\""
```

## Build di IBM i
```sh
ssh ibmi
cd ~/amna1 && git pull && makei build
```

## Aplikasi Bank DKI - Data Nasabah (CRUD)
| Object    | Tipe          | Source                     |
|-----------|---------------|----------------------------|
| `DKICUSP` | PF            | `qddssrc/dkicusp.pf`       |
| `DKICUSD` | DSPF          | `qddssrc/dkicusd.dspf`     |
| `DKICUSR` | PGM (RPGLE)   | `qrpglesrc/dkicusr.rpgle`  |
| `DKICUSC` | PGM (CLLE)    | `qclsrc/dkicusc.clle`      |

Deploy: `tools/deploy.sh qddssrc/dkicusp.pf qddssrc/dkicusd.dspf qrpglesrc/dkicusr.rpgle qclsrc/dkicusc.clle`

Jalankan dari 5250: `CALL AMNA1/DKICUSC`
- Layar list: ketik opsi `2`=Ubah, `4`=Hapus, `5`=Tampil di kolom Opt lalu Enter. F6=Tambah, F5=Refresh, F3=Keluar.
- Layar detail: isi Nama, Alamat, No Telepon lalu Enter untuk simpan. F12=Kembali, F3=Keluar.
- Hapus: layar detail tampil terkunci, tekan Enter untuk konfirmasi.

## REST API Data Nasabah (`api/`)
`GET http://185.113.5.134:3077/api/customers` → seluruh isi `AMNA1/DKICUSP` sebagai JSON (tanpa autentikasi).
Node.js (PASE) + `idb-connector`. PUB400 menolak `SBMJOB` (routing data tidak cocok), jadi server dijalankan
sebagai proses background lewat QSH.

```sh
set -a; eval "$(grep '^IBMI_' .env)"; set +a
J="java -cp tools/jt400.jar tools/Cl.java $IBMI_HOST $IBMI_USER"
# deploy + start (npm install otomatis saat pertama kali, log di /home/AMNA/amna1/api/server.log)
java -cp tools/jt400.jar tools/Push.java $IBMI_HOST $IBMI_USER $IBMI_DIR api/server.js api/package.json api/start.sh
$J "ADDENVVAR ENVVAR(QIBM_MULTI_THREADED) VALUE(Y) REPLACE(*YES)" \
   "QSH CMD('nohup /QOpenSys/usr/bin/sh /home/AMNA/amna1/api/start.sh > /dev/null 2>&1 &')"
# stop
$J "QSH CMD('kill \$(ps -u AMNA -o pid,args | grep \"node server.js\" | grep -v grep | cut -c1-10)')"
```
