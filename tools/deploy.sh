#!/bin/sh
# Push source ke IFS lalu compile di IBM i (PUB400).
# Usage: tools/deploy.sh <file>...   contoh: tools/deploy.sh qrpglesrc/hallo.rpgle
# Kredensial dibaca dari .env (IBMI_HOST, IBMI_USER, IBMI_PWD, IBMI_LIB, IBMI_DIR).
set -e
cd "$(dirname "$0")/.."
set -a; eval "$(grep '^IBMI_' .env)"; set +a
: "${IBMI_HOST:=185.113.5.134}" "${IBMI_USER:=amna}" "${IBMI_LIB:=AMNA1}" "${IBMI_DIR:=/home/AMNA/amna1}"
[ $# -gt 0 ] || { echo "usage: tools/deploy.sh <file>..."; exit 1; }
CP="tools/jt400.jar"

java -cp "$CP" tools/Push.java "$IBMI_HOST" "$IBMI_USER" "$IBMI_DIR" "$@"

cmds=""
for f in "$@"; do
  obj=$(basename "$f" | sed 's/\..*//' | tr '[:lower:]' '[:upper:]')
  src="SRCSTMF('$IBMI_DIR/$f')"
  case "$f" in
    *.sqlrpgle) cmd="CRTSQLRPGI OBJ($IBMI_LIB/$obj) $src OBJTYPE(*PGM) DBGVIEW(*SOURCE) CVTCCSID(*JOB) REPLACE(*YES)" ;;
    *.rpgle)    cmd="CRTBNDRPG PGM($IBMI_LIB/$obj) $src DBGVIEW(*SOURCE) TGTCCSID(*JOB) REPLACE(*YES)" ;;
    *.clle)     cmd="CRTBNDCL PGM($IBMI_LIB/$obj) $src DBGVIEW(*SOURCE) REPLACE(*YES)" ;;
    *) continue ;;
  esac
  set -- "$@" "$cmd"; cmds=1
done
[ -n "$cmds" ] || exit 0
# argumen asli + command compile ada di "$@"; ambil hanya command compile
shift $(( $# - $(printf '%s\n' "$@" | grep -c '^CRT') ))
java -cp "$CP" tools/Cl.java "$IBMI_HOST" "$IBMI_USER" "$@"
