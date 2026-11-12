// ============================================================================
// HOLYCOIN.HC (v1.0 Sanctuary Edition)
// Pure HolyC Bitcoin SHA-256d, 2009 Genesis Verifier, Ring-0 PoW Miner,
// Contiguous RedSea Ledger & Deterministic HolySpirit Seal for TempleOS v5.03
// ============================================================================

#define HOLYCOIN_POW_BITS   0x1f0fffff
#define INITIAL_CHAIN_LEN   4
#define REDSEA_LEDGER_PATH  "B:/HOLYCOIN.BIN"
#define DISK_LEDGER_PATH    "C:/Home/HOLYCOIN.BIN"

class CBlockHeader {
  U32 version;
  U8  prev_block[32];
  U8  merkle_root[32];
  U32 timestamp;
  U32 bits;
  U32 nonce;
};

class CSHA256Ctx {
  U32 state[8];
  U64 bit_len;
  U8  buf[64];
  I64 buf_len;
};

U32 sha256_k[64] = {
  0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,
  0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
  0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,
  0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
  0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,
  0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
  0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,
  0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
  0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,
  0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
  0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,
  0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
  0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,
  0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
  0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,
  0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2
};

U8 nist_abc_expected[32] = {
  0xba,0x78,0x16,0xbf,0x8f,0x01,0xcf,0xea,
  0x41,0x41,0x40,0xde,0x5d,0xae,0x22,0x23,
  0xb0,0x03,0x61,0xa3,0x96,0x17,0x7a,0x9c,
  0xb4,0x10,0xff,0x61,0xf2,0x00,0x15,0xad
};

U8 genesis_merkle_le[32] = {
  0x3b,0xa3,0xed,0xfd,0x7a,0x7b,0x12,0xb2,
  0x7a,0xc7,0x2c,0x3e,0x67,0x76,0x8f,0x61,
  0x7f,0xc8,0x1b,0xc3,0x88,0x8a,0x51,0x32,
  0x3a,0x9f,0xb8,0xaa,0x4b,0x1e,0x5e,0x4a
};

U8 genesis_hash_le[32] = {
  0x6f,0xe2,0x8c,0x0a,0xb6,0xf1,0xb3,0x72,
  0xc1,0xa6,0xa2,0x46,0xae,0x63,0xf7,0x4f,
  0x93,0x1e,0x83,0x65,0xe1,0x5a,0x08,0x9c,
  0x68,0xd6,0x19,0x00,0x00,0x00,0x00,0x00
};

U32 RotR32(U64 x, I64 n) {
  x = (x & 0xFFFFFFFF);
  return (((x >> n) | (x << (32 - n))) & 0xFFFFFFFF);
}

U32 ShR32(U64 x, I64 n) {
  return ((x & 0xFFFFFFFF) >> n);
}

U32 Ch32(U64 x, U64 y, U64 z) {
  return (((x & y) ^ (((~x) & 0xFFFFFFFF) & z)) & 0xFFFFFFFF);
}

U32 Maj32(U64 x, U64 y, U64 z) {
  return (((x & y) ^ (x & z) ^ (y & z)) & 0xFFFFFFFF);
}

U32 Ep0_32(U64 x) {
  return ((RotR32(x, 2) ^ RotR32(x, 13) ^ RotR32(x, 22)) & 0xFFFFFFFF);
}

U32 Ep1_32(U64 x) {
  return ((RotR32(x, 6) ^ RotR32(x, 11) ^ RotR32(x, 25)) & 0xFFFFFFFF);
}

U32 Sig0_32(U64 x) {
  return ((RotR32(x, 7) ^ RotR32(x, 18) ^ ShR32(x, 3)) & 0xFFFFFFFF);
}

U32 Sig1_32(U64 x) {
  return ((RotR32(x, 17) ^ RotR32(x, 19) ^ ShR32(x, 10)) & 0xFFFFFFFF);
}

U0 SHA256Init(CSHA256Ctx *ctx) {
  MemSet(ctx->buf, 0, 64);
  ctx->buf_len = 0;
  ctx->bit_len = 0;
  ctx->state[0] = 0x6a09e667;
  ctx->state[1] = 0xbb67ae85;
  ctx->state[2] = 0x3c6ef372;
  ctx->state[3] = 0xa54ff53a;
  ctx->state[4] = 0x510e527f;
  ctx->state[5] = 0x9b05688c;
  ctx->state[6] = 0x1f83d9ab;
  ctx->state[7] = 0x5be0cd19;
}

U0 SHA256Transform(CSHA256Ctx *ctx, U8 *blk) {
  U32 w[64];
  U64 a, b, c, d, e, f, g, h, t1, t2, b0, b1, b2, b3;
  I64 i, j;

  for (i = 0; i < 16; i++) {
    j = i * 4;
    b0 = blk[j];
    b1 = blk[j + 1];
    b2 = blk[j + 2];
    b3 = blk[j + 3];
    w[i] = (((b0 << 24) | (b1 << 16) | (b2 << 8) | b3) & 0xFFFFFFFF);
  }
  for (i = 16; i < 64; i++) {
    w[i] = ((Sig1_32(w[i - 2]) + w[i - 7] + Sig0_32(w[i - 15]) + w[i - 16]) & 0xFFFFFFFF);
  }

  a = ctx->state[0];
  b = ctx->state[1];
  c = ctx->state[2];
  d = ctx->state[3];
  e = ctx->state[4];
  f = ctx->state[5];
  g = ctx->state[6];
  h = ctx->state[7];

  for (i = 0; i < 64; i++) {
    t1 = ((h + Ep1_32(e) + Ch32(e, f, g) + sha256_k[i] + w[i]) & 0xFFFFFFFF);
    t2 = ((Ep0_32(a) + Maj32(a, b, c)) & 0xFFFFFFFF);
    h = g;
    g = f;
    f = e;
    e = ((d + t1) & 0xFFFFFFFF);
    d = c;
    c = b;
    b = a;
    a = ((t1 + t2) & 0xFFFFFFFF);
  }

  ctx->state[0] = ((ctx->state[0] + a) & 0xFFFFFFFF);
  ctx->state[1] = ((ctx->state[1] + b) & 0xFFFFFFFF);
  ctx->state[2] = ((ctx->state[2] + c) & 0xFFFFFFFF);
  ctx->state[3] = ((ctx->state[3] + d) & 0xFFFFFFFF);
  ctx->state[4] = ((ctx->state[4] + e) & 0xFFFFFFFF);
  ctx->state[5] = ((ctx->state[5] + f) & 0xFFFFFFFF);
  ctx->state[6] = ((ctx->state[6] + g) & 0xFFFFFFFF);
  ctx->state[7] = ((ctx->state[7] + h) & 0xFFFFFFFF);
}

U0 SHA256Update(CSHA256Ctx *ctx, U8 *data, I64 len) {
  I64 i;
  for (i = 0; i < len; i++) {
    ctx->buf[ctx->buf_len] = data[i];
    ctx->buf_len++;
    if (ctx->buf_len == 64) {
      SHA256Transform(ctx, ctx->buf);
      ctx->bit_len = ctx->bit_len + 512;
      ctx->buf_len = 0;
    }
  }
}

U0 SHA256Final(CSHA256Ctx *ctx, U8 *out_hash) {
  I64 i, j;
  U64 total_bits;

  total_bits = ctx->bit_len + (ctx->buf_len * 8);
  i = ctx->buf_len;
  ctx->buf[i] = 0x80;
  i++;

  if (i > 56) {
    while (i < 64) {
      ctx->buf[i] = 0;
      i++;
    }
    SHA256Transform(ctx, ctx->buf);
    i = 0;
  }
  while (i < 56) {
    ctx->buf[i] = 0;
    i++;
  }

  ctx->buf[56] = ((total_bits >> 56) & 0xFF);
  ctx->buf[57] = ((total_bits >> 48) & 0xFF);
  ctx->buf[58] = ((total_bits >> 40) & 0xFF);
  ctx->buf[59] = ((total_bits >> 32) & 0xFF);
  ctx->buf[60] = ((total_bits >> 24) & 0xFF);
  ctx->buf[61] = ((total_bits >> 16) & 0xFF);
  ctx->buf[62] = ((total_bits >> 8) & 0xFF);
  ctx->buf[63] = (total_bits & 0xFF);
  SHA256Transform(ctx, ctx->buf);

  for (i = 0; i < 8; i++) {
    j = i * 4;
    out_hash[j]     = ((ctx->state[i] >> 24) & 0xFF);
    out_hash[j + 1] = ((ctx->state[i] >> 16) & 0xFF);
    out_hash[j + 2] = ((ctx->state[i] >> 8) & 0xFF);
    out_hash[j + 3] = (ctx->state[i] & 0xFF);
  }
}

U0 SHA256(U8 *data, I64 len, U8 *out_hash) {
  CSHA256Ctx ctx;
  SHA256Init(&ctx);
  SHA256Update(&ctx, data, len);
  SHA256Final(&ctx, out_hash);
}

U0 SHA256d(U8 *data, I64 len, U8 *out_hash) {
  U8 first_pass[32];
  SHA256(data, len, first_pass);
  SHA256(first_pass, 32, out_hash);
}

U0 PutU32LE(U8 *dst, U64 v) {
  dst[0] = (v & 0xFF);
  dst[1] = ((v >> 8) & 0xFF);
  dst[2] = ((v >> 16) & 0xFF);
  dst[3] = ((v >> 24) & 0xFF);
}

U32 GetU32LE(U8 *src) {
  U64 b0, b1, b2, b3;
  b0 = src[0];
  b1 = src[1];
  b2 = src[2];
  b3 = src[3];
  return ((b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)) & 0xFFFFFFFF);
}

U0 SerializeHeader(CBlockHeader *hdr, U8 *out80) {
  PutU32LE(&out80[0], hdr->version);
  MemCpy(&out80[4], hdr->prev_block, 32);
  MemCpy(&out80[36], hdr->merkle_root, 32);
  PutU32LE(&out80[68], hdr->timestamp);
  PutU32LE(&out80[72], hdr->bits);
  PutU32LE(&out80[76], hdr->nonce);
}

U0 DeserializeHeader(U8 *in80, CBlockHeader *hdr) {
  hdr->version = GetU32LE(&in80[0]);
  MemCpy(hdr->prev_block, &in80[4], 32);
  MemCpy(hdr->merkle_root, &in80[36], 32);
  hdr->timestamp = GetU32LE(&in80[68]);
  hdr->bits = GetU32LE(&in80[72]);
  hdr->nonce = GetU32LE(&in80[76]);
}

U0 HashBlockHeader(CBlockHeader *hdr, U8 *out_hash_le) {
  U8 raw80[80];
  SerializeHeader(hdr, raw80);
  SHA256d(raw80, 80, out_hash_le);
}

Bool BytesEqual(U8 *a, U8 *b, I64 len) {
  I64 i;
  for (i = 0; i < len; i++) {
    if (a[i] != b[i]) return FALSE;
  }
  return TRUE;
}

I64 CStrLen(U8 *s) {
  I64 n = 0;
  while (s[n] != 0) n++;
  return n;
}

U0 BuildHeightCoinbase(U8 *buf, I64 h) {
  U8 digits[24];
  U8 *prefix = "HolyCoin Block #";
  U8 *suffix = ": Persistent RedSea Ledger";
  I64 d_cnt, p_len, s_len, pos, i, tmp;

  p_len = CStrLen(prefix);
  s_len = CStrLen(suffix);
  MemCpy(buf, prefix, p_len);
  pos = p_len;

  tmp = h;
  d_cnt = 0;
  if (tmp <= 0) {
    digits[0] = '0';
    d_cnt = 1;
  } else {
    while (tmp > 0) {
      digits[d_cnt] = ('0' + (tmp % 10));
      d_cnt++;
      tmp = tmp / 10;
    }
  }
  for (i = 0; i < d_cnt; i++) {
    buf[pos] = digits[d_cnt - 1 - i];
    pos++;
  }
  MemCpy(&buf[pos], suffix, s_len);
  pos = pos + s_len;
  buf[pos] = 0;
}

U0 PrintHexBE(U8 *h) {
  I64 i;
  for (i = 0; i < 32; i++) "%02x", h[31 - i];
}

U8 *OracleSealFromHash(U8 *hash_le) {
  U64 idx;
  if (god.num_words > 0 && god.words != NULL) {
    idx = (GetU32LE(hash_le) % god.num_words);
    if (god.words[idx] != NULL) return god.words[idx];
  }
  return "COVENANT";
}

U0 PrintSanctuaryBanner() {
  "$$RED$$                            |                            $$FG$$\n";
  "$$RED$$                        ====+====                        $$FG$$\n";
  "$$RED$$                            |                            $$FG$$\n";
  "$$RED$$                            |                            $$FG$$\n";
  "$$BLUE$$                  .=========+=========.                  $$FG$$\n";
  "$$BLUE$$                 /   THE HOLY TEMPLE   \\                 $$FG$$\n";
  "$$BLUE$$             ====+=====================+====             $$FG$$\n";
  "$$BROWN$$               | |$$PURPLE$$   H O L Y C O I N   $$BROWN$$| |               $$FG$$\n";
  "$$BROWN$$               |J|$$BLACK$$  RING-0 x SHA-256d  $$BROWN$$|B|               $$FG$$\n";
  "$$BROWN$$               | |$$GREEN$$  REDSEA x 0x3F8 IO  $$BROWN$$| |               $$FG$$\n";
  "$$BLUE$$             ====+=====================+====             $$FG$$\n";
  "$$DKGRAY$$           [ JACHIN ]   640 x 480   [  BOAZ  ]           $$FG$$\n\n";
}

Bool CheckProofOfWork(U8 *hash_le, U64 bits) {
  U8 target_be[32];
  I64 exp, idx, i;
  U64 mant, hb, tb;

  bits = (bits & 0xFFFFFFFF);
  exp = ((bits >> 24) & 0xFF);
  mant = (bits & 0x007FFFFF);
  if ((bits & 0x00800000) != 0) return FALSE;
  if (mant == 0 || exp < 3 || exp > 32) return FALSE;

  MemSet(target_be, 0, 32);
  idx = 32 - exp;
  target_be[idx]     = ((mant >> 16) & 0xFF);
  target_be[idx + 1] = ((mant >> 8) & 0xFF);
  target_be[idx + 2] = (mant & 0xFF);

  for (i = 0; i < 32; i++) {
    hb = hash_le[31 - i];
    tb = target_be[i];
    if (hb < tb) return TRUE;
    if (hb > tb) return FALSE;
  }
  return TRUE;
}

U0 BuildBitcoinGenesis(CBlockHeader *hdr) {
  MemSet(hdr, 0, sizeof(CBlockHeader));
  hdr->version = 1;
  MemCpy(hdr->merkle_root, genesis_merkle_le, 32);
  hdr->timestamp = 1231006505;
  hdr->bits = 0x1d00ffff;
  hdr->nonce = 2083236893;
}

Bool MineBlock(CBlockHeader *hdr, I64 height, U8 *out_hash_le) {
  U8 raw80[80];
  I64 tries, t0, elapsed_ms, hps;

  SerializeHeader(hdr, raw80);
  tries = 0;
  t0 = cnts.jiffies;

  "$$BLUE$$[Miner]$$FG$$ #%02d (bits=0x%08x) ", height, hdr->bits;
  while (TRUE) {
    PutU32LE(&raw80[76], hdr->nonce);
    SHA256d(raw80, 80, out_hash_le);
    tries++;

    if (CheckProofOfWork(out_hash_le, hdr->bits)) {
      elapsed_ms = ((cnts.jiffies - t0) * 1000) / JIFFY_FREQ;
      if (elapsed_ms <= 0) elapsed_ms = 1;
      hps = (tries * 1000) / elapsed_ms;
      "-> $$GREEN$$MINED$$FG$$ Nonce:%u (~%d H/s) Seal:$$BROWN$$%s$$FG$$\n",
        hdr->nonce, hps, OracleSealFromHash(out_hash_le);
      "        $$PURPLE$$";
      PrintHexBE(out_hash_le);
      "$$FG$$\n";
      return TRUE;
    }

    if ((tries & 0x7FF) == 0) {
      ".";
      Yield;
    }
    if (hdr->nonce == 0xFFFFFFFF) break;
    hdr->nonce++;
  }
  return FALSE;
}

Bool VerifyChain(CBlockHeader *chain, I64 count, Bool quiet) {
  I64 i;
  U8 prev_hash[32], cur_hash[32];

  if (count <= 0) return FALSE;
  for (i = 0; i < count; i++) {
    HashBlockHeader(&chain[i], cur_hash);
    if (!CheckProofOfWork(cur_hash, chain[i].bits)) {
      if (!quiet) "$$RED$$[FAIL]$$FG$$ Invalid PoW at Block #%d!\n", i;
      return FALSE;
    }
    if (i == 0) {
      if (!BytesEqual(cur_hash, genesis_hash_le, 32)) {
        if (!quiet) "$$RED$$[FAIL]$$FG$$ Block #0 is not 2009 Bitcoin Genesis!\n";
        return FALSE;
      }
    } else {
      if (!BytesEqual(chain[i].prev_block, prev_hash, 32)) {
        if (!quiet) "$$RED$$[FAIL]$$FG$$ Broken prev_block link at Block #%d!\n", i;
        return FALSE;
      }
    }
    MemCpy(prev_hash, cur_hash, 32);
  }
  return TRUE;
}

I64 SaveChainFile(U8 *path, CBlockHeader *chain, I64 count) {
  U8 *raw_buf;
  I64 i, total_bytes, clus;

  total_bytes = count * 80;
  raw_buf = MAlloc(total_bytes);
  for (i = 0; i < count; i++) {
    SerializeHeader(&chain[i], &raw_buf[i * 80]);
  }
  clus = FileWrite(path, raw_buf, total_bytes);
  Free(raw_buf);
  return clus;
}

CBlockHeader *LoadChainFile(U8 *path, I64 *out_count) {
  U8 *raw_buf;
  I64 byte_len, count, i;
  CBlockHeader *chain;

  *out_count = 0;
  if (!FileFind(path, NULL, FUF_JUST_FILES)) return NULL;
  byte_len = 0;
  raw_buf = FileRead(path, &byte_len);
  if (raw_buf == NULL) return NULL;
  if (byte_len < 80 || (byte_len % 80) != 0) {
    Free(raw_buf);
    return NULL;
  }

  count = byte_len / 80;
  chain = MAlloc(sizeof(CBlockHeader) * (count + 1));
  MemSet(chain, 0, sizeof(CBlockHeader) * (count + 1));
  for (i = 0; i < count; i++) {
    DeserializeHeader(&raw_buf[i * 80], &chain[i]);
  }
  Free(raw_buf);

  if (!VerifyChain(chain, count, FALSE)) {
    Free(chain);
    return NULL;
  }
  *out_count = count;
  return chain;
}

U0 PrintLedgerSummary(CBlockHeader *chain, I64 count) {
  I64 i;
  U8 h[32];

  "\n$$BLUE$$+--- SANCTUARY LEDGER (%d Blocks / %d Contiguous RedSea Bytes) ---+$$FG$$\n",
    count, count * 80;
  for (i = 0; i < count; i++) {
    HashBlockHeader(&chain[i], h);
    " #%02d | Nonce:%10u | $$PURPLE$$%02x%02x%02x%02x..%02x%02x$$FG$$ | Seal: $$BROWN$$%s$$FG$$\n",
      i, chain[i].nonce, h[31], h[30], h[29], h[28], h[1], h[0],
      OracleSealFromHash(h);
  }
}

U0 ResetHolyCoinLedger() {
  if (FileFind(REDSEA_LEDGER_PATH, NULL, FUF_JUST_FILES)) Del(REDSEA_LEDGER_PATH);
  if (FileFind(DISK_LEDGER_PATH, NULL, FUF_JUST_FILES)) Del(DISK_LEDGER_PATH);
  "$$BLUE$$[RESET]$$FG$$ Cleared %s and %s.\n", REDSEA_LEDGER_PATH, DISK_LEDGER_PATH;
}

U0 HolyCoinStage1B() {
  U8 digest[32], cb_dynamic[128];
  U8 *abc_msg = "abc";
  U8 *cb1 = "HolyCoin Block #1: Ring-0 TempleOS Genesis Child";
  U8 *cb2 = "HolyCoin Block #2: Pure 64-bit HolyC SHA-256d";
  U8 *cb3 = "HolyCoin Block #3: Ready for 0x3F8 Serial Relay";
  U8 *boot_cbs[3];
  CBlockHeader *chain, *reloaded;
  I64 count, reloaded_cnt, h, rs_clus, dsk_clus;

  boot_cbs[0] = cb1;
  boot_cbs[1] = cb2;
  boot_cbs[2] = cb3;

  AutoComplete(FALSE);
  WinMax;
  DocClear;
  PrintSanctuaryBanner;

  if (sizeof(CBlockHeader) != 80) return;
  SHA256(abc_msg, 3, digest);
  if (!BytesEqual(digest, nist_abc_expected, 32)) return;
  "$$GREEN$$[PASS]$$FG$$ FIPS 180-4 SHA-256(\"abc\") & 80-Byte Wire Header Verified\n";

  chain = LoadChainFile(REDSEA_LEDGER_PATH, &count);
  if (chain != NULL) {
    "$$GREEN$$[LOAD]$$FG$$ Loaded %d blocks (%d B) from RedSea (%s)\n",
      count, count * 80, REDSEA_LEDGER_PATH;
  } else {
    chain = LoadChainFile(DISK_LEDGER_PATH, &count);
    if (chain != NULL) {
      "$$GREEN$$[LOAD]$$FG$$ Restored %d blocks (%d B) from Disk (%s)\n",
        count, count * 80, DISK_LEDGER_PATH;
    }
  }

  if (chain == NULL) {
    count = INITIAL_CHAIN_LEN;
    chain = MAlloc(sizeof(CBlockHeader) * count);
    MemSet(chain, 0, sizeof(CBlockHeader) * count);

    BuildBitcoinGenesis(&chain[0]);
    HashBlockHeader(&chain[0], digest);
    if (!BytesEqual(digest, genesis_hash_le, 32) ||
        !CheckProofOfWork(digest, chain[0].bits)) {
      Free(chain);
      return;
    }
    "$$GREEN$$[PASS]$$FG$$ 2009 Bitcoin Genesis Verified (Nonce %u):\n", chain[0].nonce;
    "        $$PURPLE$$";
    PrintHexBE(digest);
    "$$FG$$\n";

    for (h = 1; h < count; h++) {
      chain[h].version = 1;
      MemCpy(chain[h].prev_block, digest, 32);
      SHA256d(boot_cbs[h - 1], CStrLen(boot_cbs[h - 1]), chain[h].merkle_root);
      chain[h].timestamp = 1231006505 + (h * 600);
      chain[h].bits = HOLYCOIN_POW_BITS;
      chain[h].nonce = 0;
      if (!MineBlock(&chain[h], h, digest)) {
        Free(chain);
        return;
      }
    }
  } else {
    h = count;
    HashBlockHeader(&chain[h - 1], digest);
    chain[h].version = 1;
    MemCpy(chain[h].prev_block, digest, 32);
    BuildHeightCoinbase(cb_dynamic, h);
    SHA256d(cb_dynamic, CStrLen(cb_dynamic), chain[h].merkle_root);
    chain[h].timestamp = chain[h - 1].timestamp + 600;
    chain[h].bits = HOLYCOIN_POW_BITS;
    chain[h].nonce = 0;
    if (!MineBlock(&chain[h], h, digest)) {
      Free(chain);
      return;
    }
    count = count + 1;
  }

  rs_clus = SaveChainFile(REDSEA_LEDGER_PATH, chain, count);
  dsk_clus = SaveChainFile(DISK_LEDGER_PATH, chain, count);
  "$$GREEN$$[SAVE]$$FG$$ RedSea %s (Sector 0x%X) | Disk %s (0x%X)\n",
    REDSEA_LEDGER_PATH, rs_clus, DISK_LEDGER_PATH, dsk_clus;

  reloaded = LoadChainFile(REDSEA_LEDGER_PATH, &reloaded_cnt);
  if (reloaded == NULL || reloaded_cnt != count) {
    if (reloaded != NULL) Free(reloaded);
    Free(chain);
    return;
  }
  reloaded[1].merkle_root[0] = (reloaded[1].merkle_root[0] ^ 0x01);
  if (!VerifyChain(reloaded, reloaded_cnt, TRUE)) {
    "$$GREEN$$[PASS]$$FG$$ RedSea Round-Trip & 1-Bit Tamper Rejection Audit Passed\n";
  }
  Free(reloaded);

  PrintLedgerSummary(chain, count);
  Free(chain);
}

HolyCoinStage1B;
