#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <assert.h>

typedef unsigned char uint8_t;
typedef unsigned short uint16_t;
typedef unsigned int uint32_t;
typedef unsigned long long uint64_t;

#define ROOTINO 1  // root i-number
#define NINODES 200
#define FSSIZE       1000  // size of file system in blocks
#define BSIZE 512  // block size
#define MAXOPBLOCKS  10  // max # of blocks any FS op writes
#define LOGSIZE      (MAXOPBLOCKS*3)  // max data blocks in on-disk log
// Directory is a file containing a sequence of dirent structures.
#define DIRSIZ 14

#define T_DIR  1   // Directory
#define T_FILE 2   // File
#define T_DEV  3   // Device

#define NDIRECT 12
#define NINDIRECT (BSIZE / sizeof(uint32_t))
#define MAXFILE (NDIRECT + NINDIRECT)
#define IPB           (BSIZE / sizeof(struct dinode))
#define IBLOCK(i, sb)     ((i) / IPB + sb.inodestart)

// On-disk inode structure
struct dinode {
  short type;           // File type
  short major;          // Major device number (T_DEV only)
  short minor;          // Minor device number (T_DEV only)
  short nlink;          // Number of links to inode in file system
  uint32_t size;            // Size of file (bytes)
  uint32_t addrs[NDIRECT+1];   // Data block addresses
};

struct superblock {
  uint32_t size;         // Size of file system image (blocks)
  uint32_t nblocks;      // Number of data blocks
  uint32_t ninodes;      // Number of inodes.
  uint32_t nlog;         // Number of log blocks
  uint32_t logstart;     // Block number of first log block
  uint32_t inodestart;   // Block number of first inode block
  uint32_t bmapstart;    // Block number of first free map block
};

struct dirent {
  uint16_t inum;
  char name[DIRSIZ];
};

#define IPB           (BSIZE / sizeof(struct dinode))

// Disk layout:
// [ boot block | sb block | log | inode blocks | free bit map | data blocks ]
int nbitmap = FSSIZE/(BSIZE*8) + 1;
int ninodeblocks = NINODES / IPB + 1;
int nlog = LOGSIZE;
int nmeta;    // Number of meta blocks (boot, sb, nlog, inode, bitmap)
int nblocks;  // Number of data blocks

// FILE *fsfd;
int fsfd;
struct superblock sb;
char zeroes[BSIZE];
uint32_t freeinode = 1;
uint32_t freeblock;

void balloc(int);
void wsect(uint32_t, void*);
void winode(uint32_t, struct dinode*);
void rinode(uint32_t inum, struct dinode *ip);
void rsect(uint32_t sec, void *buf);
uint32_t ialloc(uint16_t type);
void iappend(uint32_t inum, void *p, int n);

// convert to intel byte order
uint16_t
xshort(uint16_t x)
{
  uint16_t y;
  uint8_t *a = (uint8_t*)&y;
  a[0] = x;
  a[1] = x >> 8;
  return y;
}

uint32_t
xint(uint32_t x)
{
  uint32_t y;
  uint8_t *a = (uint8_t*)&y;
  a[0] = x;
  a[1] = x >> 8;
  a[2] = x >> 16;
  a[3] = x >> 24;
  return y;
}

int
main(void)
{
  uint32_t rootino, inum, off;
  struct dirent de;
  char buf[BSIZE];
  struct dinode din;

  // fsfd = fopen("superblock", "wb");
  fsfd = open("superblock", O_RDWR|O_CREAT|O_TRUNC, 0666);
  if (fsfd == 0)
    printf("error\n");
  // 1 fs block = 1 disk sector
  nmeta = 2 + nlog + ninodeblocks + nbitmap;
  nblocks = FSSIZE - nmeta;

  sb.size = xint(FSSIZE);
  sb.nblocks = xint(nblocks);
  sb.ninodes = xint(NINODES);
  sb.nlog = xint(nlog);
  sb.logstart = xint(2);
  sb.inodestart = xint(2+nlog);
  sb.bmapstart = xint(2+nlog+ninodeblocks);
  // printf("bmap: %u\n", sb.bmapstart);

  printf("nmeta %d (boot, super, log blocks %u inode blocks %u, bitmap blocks %u) blocks %d total %d\n",
         nmeta, nlog, ninodeblocks, nbitmap, nblocks, FSSIZE);
  
  freeblock = nmeta;

  memset(buf, 0, sizeof(buf));

  for (int i = 0; i < FSSIZE; i++)
    wsect(i, buf);

  // printf("after init.\n");
  // fseek(fsfd, 0, 0);
  memmove(buf, &sb, sizeof(sb));
  // fwrite(buf, sizeof(char), BSIZE, fsfd);
  wsect(0, buf);

  rootino = ialloc(T_DIR);
  assert(rootino == ROOTINO);
  bzero(&de, sizeof(de));
  de.inum = xshort(rootino);
  strcpy(de.name, ".");
  iappend(rootino, &de, sizeof(de));

  bzero(&de, sizeof(de));
  de.inum = xshort(rootino);
  strcpy(de.name, "..");
  iappend(rootino, &de, sizeof(de));
  
  // fix size of root inode dir
  rinode(rootino, &din);
  off = xint(din.size);
  off = ((off/BSIZE) + 1) * BSIZE;
  din.size = xint(off);
  winode(rootino, &din);

  balloc(freeblock);
  // fclose(fsfd);
  exit(0);
}

void
wsect(uint32_t sec, void *buf)
{
  // printf("sec: %d\n", sec);
  // fseek(fsfd, sec * BSIZE, SEEK_SET);
  // printf("after fseek.\n");
  // fwrite(buf, sizeof(char), BSIZE, fsfd);
  if(lseek(fsfd, sec * BSIZE, 0) != sec * BSIZE){
    printf("error: wsect lseek: %d\n", sec);
    exit(1);
  }
  if(write(fsfd, buf, BSIZE) != BSIZE){
    printf("error: wsect write: %d\n", sec);
    exit(1);
  }
}

void
winode(uint32_t inum, struct dinode *ip)
{
  char buf[BSIZE];
  uint32_t bn;
  struct dinode *dip;

  bn = IBLOCK(inum, sb) - 1;
  rsect(bn, buf);
  printf("bn: %d, inum: %d\n", bn, inum);
  dip = ((struct dinode*)buf) + (inum % IPB);
  *dip = *ip;
  wsect(bn, buf);
}

void
rinode(uint32_t inum, struct dinode *ip)
{
  char buf[BSIZE];
  uint32_t bn;
  struct dinode *dip;

  bn = IBLOCK(inum, sb) - 1;
  rsect(bn, buf);
  dip = ((struct dinode*)buf) + (inum % IPB);
  *ip = *dip;
}

void
rsect(uint32_t sec, void *buf)
{
  // fseek(fsfd, sec * BSIZE, SEEK_SET);
  // fread(buf, sizeof(char), BSIZE, fsfd);
  if(lseek(fsfd, sec * BSIZE, 0) != sec * BSIZE){
    printf("error: rsect lseek: %d\n", sec);
    exit(1);
  }
  if(read(fsfd, buf, BSIZE) != BSIZE){
    printf("error: rsect read: %d\n", sec);
    exit(1);
  }
}

uint32_t
ialloc(uint16_t type)
{
  uint32_t inum = freeinode++;
  struct dinode din;

  bzero(&din, sizeof(din));
  din.type = xshort(type);
  din.nlink = xshort(1);
  din.size = xint(0);
  winode(inum, &din);
  return inum;
}

void
balloc(int used)
{
  uint8_t buf[BSIZE];
  int i;

  printf("balloc: first %d blocks have been allocated\n", used);
  assert(used < BSIZE*8);
  bzero(buf, BSIZE);
  for (i = 0; i < used; i++) {
    buf[i/8] = buf[i/8] | (0x1 << (i%8));
  }
  printf("balloc: write bitmap block at sector %d\n", sb.bmapstart);
  wsect(sb.bmapstart - 1, buf);
}

#define min(a, b) ((a) < (b) ? (a) : (b))

void
iappend(uint32_t inum, void *xp, int n)
{
  char *p = (char*)xp;
  uint32_t fbn, off, n1;
  struct dinode din;
  char buf[BSIZE];
  uint32_t indirect[NINDIRECT];
  uint32_t x;

  rinode(inum, &din);
  off = xint(din.size);
  printf("append inum %d at off %d sz %d\n", inum, off, n);
  while (n > 0) {
    fbn = off / BSIZE;
    assert(fbn < MAXFILE);
    if (fbn < NDIRECT) {
      if (xint(din.addrs[fbn]) == 0) {
        din.addrs[fbn] = xint(freeblock++);
      }
      x = xint(din.addrs[fbn]);
    } else {
      if (xint(din.addrs[NDIRECT]) == 0) {
        din.addrs[NDIRECT] = xint(freeblock++);
      }
      rsect(xint(din.addrs[NDIRECT]) - 1, (char*)indirect);
      if (indirect[fbn - NDIRECT] == 0) {
        indirect[fbn - NDIRECT] = xint(freeblock++);
        wsect(xint(din.addrs[NDIRECT]) - 1, (char*)indirect);
      }
      x = xint(indirect[fbn-NDIRECT]);
    }
    n1 = min(n, (fbn + 1) * BSIZE - off);
    rsect(x - 1, buf);
    printf("x: %d, n1: %d\n", x, n1);
    bcopy(p, buf + off - (fbn * BSIZE), n1);
    wsect(x - 1, buf);
    n -= n1;
    off += n1;
    p += n1;
  }
  din.size = xint(off);
  winode(inum, &din);
}
