#!/bin/bash
# Push source ke IBM i (PUB400), salin ke source member, lalu compile dari member.
# Usage: tools/deploy.sh <file>...   contoh: tools/deploy.sh qrpglesrc/hallo.rpgle
# Kredensial dibaca dari .env (IBMI_HOST, IBMI_USER, IBMI_PWD, IBMI_LIB, IBMI_DIR).
# Folder = source file (qrpglesrc/x.rpgle -> AMNA1/QRPGLESRC(X)), ekstensi = tipe member.
# Compile berurutan PF -> LF -> DSPF -> program, supaya program menemukan file yang dipakainya.
set -e
cd "$(dirname "$0")/.."
set -a; eval "$(grep '^IBMI_' .env)"; set +a
: "${IBMI_HOST:=185.113.5.134}" "${IBMI_USER:=amna}" "${IBMI_LIB:=AMNA1}" "${IBMI_DIR:=/home/AMNA/amna1}"
[ $# -gt 0 ] || { echo "usage: tools/deploy.sh <file>..."; exit 1; }
L=$IBMI_LIB

cl() { java -cp tools/jt400.jar tools/Cl.java "$IBMI_HOST" "$IBMI_USER" "CHGCURLIB CURLIB($L)" "$@"; }

# IFS dipakai sebagai tempat transit file dari Mac ke server
java -cp tools/jt400.jar tools/Push.java "$IBMI_HOST" "$IBMI_USER" "$IBMI_DIR" "$@"

for pass in pf lf dspf pgm; do
  for f in "$@"; do
    obj=$(basename "$f" | sed 's/\..*//' | tr '[:lower:]' '[:upper:]')
    srcf=$(basename "$(dirname "$f")" | tr '[:lower:]' '[:upper:]')
    type=$(echo "${f##*.}" | tr '[:lower:]' '[:upper:]')
    src="SRCFILE($L/$srcf) SRCMBR($obj)"
    tombr="CPYFRMSTMF FROMSTMF('$IBMI_DIR/$f') TOMBR('/QSYS.LIB/$L.LIB/$srcf.FILE/$obj.MBR') MBROPT(*REPLACE)"
    settype="CHGPFM FILE($L/$srcf) MBR($obj) SRCTYPE($type)"
    case "$pass:$f" in
      pf:*.pf)
        # PF yang sudah ada diubah dengan CHGPF supaya datanya tidak hilang
        if cl "CHKOBJ OBJ($L/$obj) OBJTYPE(*FILE)" >/dev/null 2>&1; then
          make="CHGPF FILE($L/$obj) $src"
        else
          make="CRTPF FILE($L/$obj) $src"
        fi
        cl "$tombr" "$settype" "$make" ;;
      lf:*.lf)
        # LF tidak menyimpan data, jadi aman dihapus lalu dibuat ulang
        if cl "CHKOBJ OBJ($L/$obj) OBJTYPE(*FILE)" >/dev/null 2>&1; then
          cl "DLTF FILE($L/$obj)"
        fi
        cl "$tombr" "$settype" "CRTLF FILE($L/$obj) $src" ;;
      dspf:*.dspf)
        cl "$tombr" "$settype" "CRTDSPF FILE($L/$obj) $src REPLACE(*YES)" ;;
      pgm:*.sqlrpgle)
        cl "$tombr" "$settype" "CRTSQLRPGI OBJ($L/$obj) $src OBJTYPE(*PGM) DBGVIEW(*SOURCE) REPLACE(*YES)" ;;
      pgm:*.rpgle)
        cl "$tombr" "$settype" "CRTBNDRPG PGM($L/$obj) $src DBGVIEW(*SOURCE) REPLACE(*YES)" ;;
      pgm:*.clle)
        cl "$tombr" "$settype" "CRTBNDCL PGM($L/$obj) $src DBGVIEW(*SOURCE) REPLACE(*YES)" ;;
    esac
  done
done
