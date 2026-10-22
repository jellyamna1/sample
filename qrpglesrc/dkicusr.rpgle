**free
// ---------------------------------------------------------------------
// Program  : DKICUSR
// Desc     : Bank DKI - Maintenance data nasabah (CRUD)
//            List nasabah di subfile, opsi 2=Ubah 4=Hapus 5=Tampil,
//            F6=Tambah. Data disimpan di PF DKICUSP.
// Files    : DKICUSP  (PF)   - master nasabah, key CUSID
//            DKICUSD  (DSPF) - layar list + detail
// Called by: DKICUSC (CL)
// ---------------------------------------------------------------------
// Modification log
// Date        Author       Description
// ----------  -----------  ---------------------------------------------
// 22-10-2026  jelly.amna   Initial version
// ---------------------------------------------------------------------
ctl-opt dftactgrp(*no) actgrp(*new)
        option(*srcstmt:*nodebugio)
        datfmt(*iso) timfmt(*iso);

// ---------------------------------------------------------------------
// Files
// ---------------------------------------------------------------------
dcl-f DKICUSP usage(*update:*delete:*output) keyed;
dcl-f DKICUSD workstn sfile(DKISFL:wRrn) indds(dspInd);

// ---------------------------------------------------------------------
// Indikator layar (INDARA)
// ---------------------------------------------------------------------
dcl-ds dspInd qualified;
  exit        ind pos(3);
  refresh     ind pos(5);
  add         ind pos(6);
  cancel      ind pos(12);
  sflDsp      ind pos(31);
  sflDspCtl   ind pos(32);
  sflClr      ind pos(33);
  sflEnd      ind pos(34);
  protect     ind pos(40);
  confirmDel  ind pos(41);
  errNama     ind pos(50);
  errAlamat   ind pos(51);
  errTlp      ind pos(52);
end-ds;

// ---------------------------------------------------------------------
// Konstanta
// ---------------------------------------------------------------------
dcl-c MODE_ADD     'A';
dcl-c MODE_CHG     'C';
dcl-c MODE_DSP     'D';
dcl-c MODE_DLT     'X';

dcl-c OPT_CHG      '2';
dcl-c OPT_DLT      '4';
dcl-c OPT_DSP      '5';

dcl-c ST_DUPKEY    01021;
dcl-c ST_LOCKED    01218;
dcl-c MAX_RETRY    3;
dcl-c SFL_MAX      9999;
dcl-c TLP_CHARS    '0123456789+-() ';

// ---------------------------------------------------------------------
// Work fields
// ---------------------------------------------------------------------
dcl-s wRrn         packed(4:0);
dcl-s wSflCount    packed(4:0);

// =====================================================================
// Mainline
// =====================================================================
loadSubfile();

dou dspInd.exit;
  write DKIFTR;
  exfmt DKICTL;
  FMSG = *blanks;

  select;
    when dspInd.exit;
      // keluar
    when dspInd.refresh;
      loadSubfile();
    when dspInd.add;
      showDetail(MODE_ADD : 0);
      loadSubfile();
    other;
      processOptions();
  endsl;
enddo;

*inlr = *on;
return;

// ---------------------------------------------------------------------
// loadSubfile - isi ulang subfile dari DKICUSP (urut ID)
// ---------------------------------------------------------------------
dcl-proc loadSubfile;

  dspInd.sflDsp    = *off;
  dspInd.sflDspCtl = *off;
  dspInd.sflClr    = *on;
  write DKICTL;
  dspInd.sflClr    = *off;

  wRrn = 0;
  setll *loval DKICUSP;
  read(n) DKICUSP;
  dow not %eof(DKICUSP) and wRrn < SFL_MAX;
    SFOPT = *blanks;
    SFID  = CUSID;
    SFNAM = CUSNAM;
    SFTLP = CUSTLP;
    wRrn += 1;
    write DKISFL;
    read(n) DKICUSP;
  enddo;

  wSflCount        = wRrn;
  dspInd.sflDsp    = (wSflCount > 0);
  dspInd.sflDspCtl = *on;
  dspInd.sflEnd    = *on;

  if wSflCount = 0 and FMSG = *blanks;
    FMSG = 'Belum ada data nasabah. Tekan F6 untuk menambah.';
  endif;

end-proc;

// ---------------------------------------------------------------------
// processOptions - proses opsi yang diketik user di subfile
// ---------------------------------------------------------------------
dcl-proc processOptions;

  if wSflCount = 0;
    return;
  endif;

  readc DKISFL;
  dow not %eof(DKICUSD) and not dspInd.exit;
    select;
      when SFOPT = OPT_CHG;
        showDetail(MODE_CHG : SFID);
      when SFOPT = OPT_DLT;
        showDetail(MODE_DLT : SFID);
      when SFOPT = OPT_DSP;
        showDetail(MODE_DSP : SFID);
    endsl;
    readc DKISFL;
  enddo;

  loadSubfile();

end-proc;

// ---------------------------------------------------------------------
// showDetail - layar detail untuk tambah / ubah / tampil / hapus
// ---------------------------------------------------------------------
dcl-proc showDetail;
  dcl-pi *n;
    pMode  char(1)      const;
    pId    packed(7:0)  const;
  end-pi;

  DID  = 0;
  DNAM = *blanks;
  DALM = *blanks;
  DTLP = *blanks;
  DMSG = *blanks;
  dspInd.errNama   = *off;
  dspInd.errAlamat = *off;
  dspInd.errTlp    = *off;

  if pMode <> MODE_ADD;
    chain(n) pId DKICUSP;
    if not %found(DKICUSP);
      FMSG = 'Nasabah ' + %char(pId) + ' tidak ditemukan.';
      return;
    endif;
    DID  = CUSID;
    DNAM = CUSNAM;
    DALM = CUSALM;
    DTLP = CUSTLP;
  endif;

  dspInd.protect    = (pMode = MODE_DSP or pMode = MODE_DLT);
  dspInd.confirmDel = (pMode = MODE_DLT);

  select;
    when pMode = MODE_ADD;
      DMODE = 'TAMBAH NASABAH';
    when pMode = MODE_CHG;
      DMODE = 'UBAH NASABAH';
    when pMode = MODE_DSP;
      DMODE = 'TAMPIL NASABAH';
    when pMode = MODE_DLT;
      DMODE = 'HAPUS NASABAH';
  endsl;

  dow *on;
    exfmt DKIDTL;
    DMSG = *blanks;

    if dspInd.exit or dspInd.cancel or pMode = MODE_DSP;
      leave;
    endif;

    if pMode = MODE_DLT;
      if deleteCustomer(pId);
        leave;
      endif;
      iter;
    endif;

    if not validInput();
      iter;
    endif;

    if pMode = MODE_ADD;
      if addCustomer();
        leave;
      endif;
    elseif updateCustomer(pId);
      leave;
    endif;
  enddo;

end-proc;

// ---------------------------------------------------------------------
// validInput - validasi field layar detail, set indikator error
// ---------------------------------------------------------------------
dcl-proc validInput;
  dcl-pi *n ind end-pi;

  dspInd.errNama   = (DNAM = *blanks);
  dspInd.errAlamat = (DALM = *blanks);
  dspInd.errTlp    = (DTLP = *blanks or %check(TLP_CHARS : DTLP) > 0);

  select;
    when dspInd.errNama;
      DMSG = 'Nama wajib diisi.';
    when dspInd.errAlamat;
      DMSG = 'Alamat wajib diisi.';
    when dspInd.errTlp;
      DMSG = 'No telepon wajib diisi, hanya angka dan + - ( ).';
  endsl;

  return not (dspInd.errNama or dspInd.errAlamat or dspInd.errTlp);

end-proc;

// ---------------------------------------------------------------------
// addCustomer - tulis nasabah baru, ID = ID terakhir + 1.
//               Retry bila ID sudah dipakai job lain (duplicate key).
// ---------------------------------------------------------------------
dcl-proc addCustomer;
  dcl-pi *n ind end-pi;

  dcl-s attempt int(10);

  for attempt = 1 to MAX_RETRY;
    CUSID  = nextId();
    CUSNAM = DNAM;
    CUSALM = DALM;
    CUSTLP = DTLP;
    write(e) DKICUSF;
    if not %error() or %status(DKICUSP) <> ST_DUPKEY;
      leave;
    endif;
  endfor;

  if %error();
    DMSG = 'Gagal menyimpan nasabah (status ' + %char(%status(DKICUSP)) + ').';
    return *off;
  endif;

  FMSG = 'Nasabah ' + %char(CUSID) + ' berhasil ditambahkan.';
  return *on;

end-proc;

// ---------------------------------------------------------------------
// updateCustomer - ubah nama, alamat, telepon nasabah
// ---------------------------------------------------------------------
dcl-proc updateCustomer;
  dcl-pi *n ind;
    pId  packed(7:0) const;
  end-pi;

  chain(e) pId DKICUSP;
  if %error();
    DMSG = lockMessage();
    return *off;
  endif;
  if not %found(DKICUSP);
    FMSG = 'Nasabah ' + %char(pId) + ' sudah tidak ada.';
    return *on;
  endif;

  CUSNAM = DNAM;
  CUSALM = DALM;
  CUSTLP = DTLP;
  update DKICUSF %fields(CUSNAM : CUSALM : CUSTLP);

  FMSG = 'Nasabah ' + %char(pId) + ' berhasil diubah.';
  return *on;

end-proc;

// ---------------------------------------------------------------------
// deleteCustomer - hapus nasabah
// ---------------------------------------------------------------------
dcl-proc deleteCustomer;
  dcl-pi *n ind;
    pId  packed(7:0) const;
  end-pi;

  chain(e) pId DKICUSP;
  if %error();
    DMSG = lockMessage();
    return *off;
  endif;
  if not %found(DKICUSP);
    FMSG = 'Nasabah ' + %char(pId) + ' sudah tidak ada.';
    return *on;
  endif;

  delete DKICUSF;

  FMSG = 'Nasabah ' + %char(pId) + ' berhasil dihapus.';
  return *on;

end-proc;

// ---------------------------------------------------------------------
// nextId - ID nasabah berikutnya (ID terbesar + 1)
// ---------------------------------------------------------------------
dcl-proc nextId;
  dcl-pi *n packed(7:0) end-pi;

  setgt *hival DKICUSP;
  readp(n) DKICUSP;
  if %eof(DKICUSP);
    return 1;
  endif;
  return CUSID + 1;

end-proc;

// ---------------------------------------------------------------------
// lockMessage - pesan bila record gagal dibaca untuk update
// ---------------------------------------------------------------------
dcl-proc lockMessage;
  dcl-pi *n varchar(78) end-pi;

  if %status(DKICUSP) = ST_LOCKED;
    return 'Data sedang dipakai user lain, coba lagi.';
  endif;
  return 'Gagal membaca data (status ' + %char(%status(DKICUSP)) + ').';

end-proc;
