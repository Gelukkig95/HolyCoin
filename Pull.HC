U8 Rx() {
  U8 b;
  while (!(InU8(0x3FD)&1));
  b=InU8(0x3F8);
  while (!(InU8(0x3FD)&0x20));
  OutU8(0x3F8,6);
  return b;
}

U0 Pull(U8 *fn) {
  I64 i,lo,hi,n;
  U8 *buf;
  OutU8(0x3F9,0);
  OutU8(0x3FB,3);
  while (InU8(0x3FD)&1) InU8(0x3F8);
  while (!(InU8(0x3FD)&0x20));
  OutU8(0x3F8,'R');
  lo=Rx();
  hi=Rx();
  n=lo+hi*256;
  buf=MAlloc(n);
  for (i=0;i<n;i++) buf[i]=Rx();
  FileWrite(fn,buf,n);
  Free(buf);
  "Saved %s (%d bytes)\n",fn,n;
}
