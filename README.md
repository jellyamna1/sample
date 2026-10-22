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

# Jalankan query SQL
IBMI_PWD=... java -cp tools/jt400.jar tools/Sql.java 185.113.5.134 amna "SELECT * FROM AMNA1.\"USER\""
```

## Build di IBM i
```sh
ssh ibmi
cd ~/amna1 && git pull && makei build
```
