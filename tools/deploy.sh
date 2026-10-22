#!/bin/bash
# Push source ke IFS lalu compile di IBM i (PUB400).
# Usage: tools/deploy.sh <file>...   contoh: tools/deploy.sh qrpglesrc/hallo.rpgle
# Kredensial dibaca dari .env (IBMI_HOST, IBMI_USER, IBMI_PWD, IBMI_LIB, IBMI_DIR).
# Compile berurutan PF -> DSPF -> program, supaya program menemukan file yang dipakainya.
set -e
cd "$(dirname "$0")/.."
set -a; eval "$(grep '^IBMI_' .env)"; set +a
: "${IBMI_HOST:=185.113.5.134}" "${IBMI_USER:=amna}" "${IBMI_LIB:=AMNA1}" "${IBMI_DIR:=/home/AMNA/amna1}"
[ $# -gt 0 ] || { echo "usage: tools/deploy.sh <file>..."; exit 1; }
L=$IBMI_LIB

cl() { java -cp tools/jt400.jar tools/Cl.java "$IBMI_HOST" "$IBMI_USER" "CHGCURLIB CURLIB($L)" "$@"; }

java -cp tools/jt400.jar tools/Push.java "$IBMI_HOST" "$IBMI_USER" "$IBMI_DIR" "$@"

for pass in pf dspf pgm; do
  for f in "$@"; do
    obj=$(basename "$f" | sed 's/\..*//' | tr '[:lower:]' '[:upper:]')
    stmf="$IBMI_DIR/$f"
    # DDS di-compile dari source member, jadi stream file disalin dulu ke QDDSSRC
    tombr="CPYFRMSTMF FROMSTMF('$stmf') TOMBR('/QSYS.LIB/$L.LIB/QDDSSRC.FILE/$obj.MBR') MBROPT(*REPLACE)"
    case "$pass:$f" in
      pf:*.pf)
        # PF yang sudah ada diubah dengan CHGPF supaya datanya tidak hilang
        if cl "CHKOBJ OBJ($L/$obj) OBJTYPE(*FILE)" >/dev/null 2>&1; then
          make="CHGPF FILE($L/$obj) SRCFILE($L/QDDSSRC) SRCMBR($obj)"
        else
          make="CRTPF FILE($L/$obj) SRCFILE($L/QDDSSRC) SRCMBR($obj)"
        fi
        cl "$tombr" "CHGPFM FILE($L/QDDSSRC) MBR($obj) SRCTYPE(PF)" "$make" ;;
      dspf:*.dspf)
        cl "$tombr" "CHGPFM FILE($L/QDDSSRC) MBR($obj) SRCTYPE(DSPF)" \
           "CRTDSPF FILE($L/$obj) SRCFILE($L/QDDSSRC) SRCMBR($obj) REPLACE(*YES)" ;;
      pgm:*.sqlrpgle)
        cl "CRTSQLRPGI OBJ($L/$obj) SRCSTMF('$stmf') OBJTYPE(*PGM) DBGVIEW(*SOURCE) CVTCCSID(*JOB) REPLACE(*YES)" ;;
      pgm:*.rpgle)
        cl "CRTBNDRPG PGM($L/$obj) SRCSTMF('$stmf') DBGVIEW(*SOURCE) TGTCCSID(*JOB) REPLACE(*YES)" ;;
      pgm:*.clle)
        cl "CRTBNDCL PGM($L/$obj) SRCSTMF('$stmf') DBGVIEW(*SOURCE) REPLACE(*YES)" ;;
    esac
  done
done
