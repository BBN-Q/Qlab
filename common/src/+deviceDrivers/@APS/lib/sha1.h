#ifndef _SHA1_H_
#define _SHA1_H_

#include <stdint.h>


#ifdef __cplusplus
extern "C" {
#endif

#define SHA1HashSize 20
#define SHA1BlockSize 64

typedef struct
{
    uint32_t hash[SHA1HashSize/4]; /* 20 byte Hash processed as uint32_ts */
    uint8_t block[SHA1BlockSize];  /* 512-bit message blocks */
    uint8_t idx; /* index into block */
    uint32_t length; /* length in bits */
} SHA1Context_t;

int sha1_init(SHA1Context_t *context);
void sha1_update(SHA1Context_t *c,uint8_t *bytes, uint32_t length);
void sha1_finish(SHA1Context_t *c, uint8_t * hash);
int sha1_verify(uint8_t * hash1 , uint8_t * hash2);

#ifdef __cplusplus
}
#endif

#endif

