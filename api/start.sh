#!/QOpenSys/usr/bin/sh
# Start DKI REST API di IBM i. Dipanggil lewat SBMJOB (lihat README), log ke server.log.
export PATH=/QOpenSys/pkgs/bin:$PATH
cd "$(dirname "$0")" || exit 1
[ -d node_modules ] || npm install --omit=dev >> server.log 2>&1
exec node server.js >> server.log 2>&1
