// ---------------------------------------------------------------------
// DKI REST API - data nasabah Bank DKI (PF AMNA1/DKICUSP)
// GET /api/customers  -> seluruh isi DKICUSP sebagai JSON array
// Jalan di IBM i (PASE) dengan Node.js + idb-connector, lihat start.sh
// ---------------------------------------------------------------------
const http = require('http');
const { dbconn, dbstmt } = require('idb-connector');

const PORT = Number(process.env.PORT) || 3077;
const SQL_CUSTOMERS = `
  SELECT CUSID         AS "id",
         TRIM(CUSNAM)  AS "nama",
         TRIM(CUSALM)  AS "alamat",
         TRIM(CUSTLP)  AS "telepon"
    FROM AMNA1.DKICUSP
   ORDER BY CUSID`;

function queryCustomers() {
  return new Promise((resolve, reject) => {
    const conn = new dbconn();
    conn.conn('*LOCAL');
    const stmt = new dbstmt(conn);
    stmt.exec(SQL_CUSTOMERS, (rows, err) => {
      stmt.close();
      conn.disconn();
      conn.close();
      if (err) return reject(err);
      // packed decimal dari DB2 datang sebagai string
      resolve(rows.map((r) => ({ ...r, id: Number(r.id) })));
    });
  });
}

function send(res, status, body) {
  res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify(body));
}

const server = http.createServer(async (req, res) => {
  const path = req.url.split('?')[0];
  if (req.method !== 'GET' || path !== '/api/customers') {
    return send(res, 404, { error: 'Not found' });
  }
  try {
    send(res, 200, await queryCustomers());
  } catch (err) {
    console.error(new Date().toISOString(), err);
    send(res, 500, { error: 'Gagal membaca data nasabah' });
  }
});

server.listen(PORT, () => console.log(new Date().toISOString(), `DKI API listening on port ${PORT}`));
