const https = require('node:https');
const fs = require('node:fs');
const hosts = fs.readdirSync('/security/chains').filter(x => x.endsWith('.pem')).map(x => x.slice(0, -4));
function check(host, blocked) {
  return new Promise((resolve, reject) => {
    const req = https.get('https://' + host, { timeout: 15000 }, res => {
      res.destroy();
      blocked ? reject(new Error('Compromised chain accepted: ' + host)) : resolve();
    });
    req.on('timeout', () => req.destroy(new Error('Network timeout: ' + host)));
    req.on('error', error => {
      if (blocked && ['CERT_REVOKED', 'UNABLE_TO_GET_ISSUER_CERT_LOCALLY', 'UNABLE_TO_VERIFY_LEAF_SIGNATURE', 'SELF_SIGNED_CERT_IN_CHAIN'].includes(error.code)) {
        console.log('PASS:', host, error.code); resolve();
      } else reject(error);
    });
  });
}
(async () => {
  await check('example.com', false);
  for (const host of hosts) await check(host, true);
})().catch(error => { console.error(error); process.exit(1); });
