import crypto from 'crypto';

function access(r) {
    const SECRET = "SANSHENG";
    const thirtyMinutesWindow = 1800000;
    const uri = r.uri;
    const internalPath = uri.replace('/s3/', '/_s3_internal/');

    // 白名单 → public 目录
    if (uri.startsWith('/s3/public')) {
        r.internalRedirect(internalPath);
        return;
    }

    // 读取签名
    const timestamp = r.args.timestamp;
    const nonce = r.args.nonce;
    const sign = r.args.sign;

    if (!timestamp || !nonce || !sign) {
        r.return(403);
        return;
    }

    const clientTimestamp = parseInt(timestamp);
    if (isNaN(clientTimestamp)) {
        return;
    }
    const now = Date.now();
    const diff = Math.abs(now - clientTimestamp);
    if (diff > thirtyMinutesWindow) {
        r.return(403, "Request Expired");
        return;
    }

    // 验证签名
    const rawString = timestamp + nonce + SECRET;
    const hash = crypto.createHash('md5').update(rawString).digest('hex');

    if (hash.toLowerCase() === sign.toLowerCase()) {
        r.internalRedirect(internalPath);
    } else {
        r.return(403);
    }
}

export default {access};