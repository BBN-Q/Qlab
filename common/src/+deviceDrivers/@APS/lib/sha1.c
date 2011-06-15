/* BBN Implementation of SHA1 Algorithim
 *
 * This implementation is based on the more general implementation in
 * RFC 3174 and the Pseudocode on wikipedia.
 *
 * For original spec see FIPS 180-2 from NIST
 *
 * See:
 * http://en.wikipedia.org/wiki/SHA-1
 * http://tools.ietf.org/html/rfc3174
 * http://csrc.nist.gov/groups/ST/toolkit/secure_hashing.html
 */


#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include "sha1.h"

/*
 *  Define the SHA1 circular left shift macro
 */
#define SHA1Shift(bits,word) (((word) << (bits)) | ((word) >> (32-(bits))))

/*
 *  Initialize SHA1 context as defined by FIPS
 *  180-1
 */
int sha1_init(SHA1Context_t *context)
{
    context->hash[0]   = 0x67452301;
    context->hash[1]   = 0xEFCDAB89;
    context->hash[2]   = 0x98BADCFE;
    context->hash[3]   = 0x10325476;
    context->hash[4]   = 0xC3D2E1F0;
    context->idx = 0;
    memset(&(context->block), 0, SHA1BlockSize);
    context->length = 0;
    return 0;
}

/*
 * Process 64 Byte block of data and update hash context
 */
void sha1_process(SHA1Context_t *c) {

	const uint32_t K[] = {0x5A827999,
	                      0x6ED9EBA1, 
						  0x8F1BBCDC, 
						  0xCA62C1D6};

	int cnt;
	uint32_t tmp;
	uint32_t W[80];
	uint32_t A,B,C,D,E,F;
	uint32_t kval;

	for(cnt = 0; cnt < 16; cnt++) {
		// operate a uint32_t at a time with byte swapping from little endian
		// to bit endian
		W[cnt] =  c->block[cnt * 4] << 24;
		W[cnt] |= c->block[cnt * 4 + 1] << 16;
		W[cnt] |= c->block[cnt * 4 + 2] << 8;
		W[cnt] |= c->block[cnt * 4 + 3];
	}

	// initialized remainder of work area as defined
	for(cnt = 16; cnt < 80; cnt++) {
		W[cnt] = SHA1Shift(1,W[cnt-3] ^ W[cnt-8] ^ W[cnt-14] ^ W[cnt-16]);
	}

	A = c->hash[0];
	B = c->hash[1];
	C = c->hash[2];
	D = c->hash[3];
	E = c->hash[4];

	// process each block in 80 rounds
	for (cnt = 0; cnt < 80; cnt++) {

		if (cnt >= 0 && cnt < 20) {
			F = ((B & C) | ((~B) & D));
			kval = K[0];
		} else if (cnt >= 20 && cnt < 40){
			F = (B ^ C ^ D);
			kval = K[1];
		} else if (cnt >= 40 && cnt < 60){
			F = ((B & C) | (B & D) | (C & D));
			kval = K[2];
		} else if (cnt >= 60 && cnt < 80){
			F = (B ^ C ^ D);
			kval = K[3];
		}

		tmp = SHA1Shift(5,A) + F + E + W[cnt] + kval;
		E = D;
		D = C;
		C = SHA1Shift(30,B);
		B = A;
		A = tmp;
	}

	// update hash
	c->hash[0] += A;
	c->hash[1] += B;
	c->hash[2] += C;
	c->hash[3] += D;
	c->hash[4] += E;
	c->idx = 0;
}

void sha1_update(SHA1Context_t *c,uint8_t *bytes, uint32_t length) {
	uint8_t *ptr;
	ptr = bytes;

	while(length--) {
		c->block[c->idx++] = (*ptr & 0xFF);
		c->length += 8;
		if (c->idx == 64)
			sha1_process(c);
		ptr++;
	}
}

void sha1_finish(SHA1Context_t *c, uint8_t * hash) {
	int cnt;

	// add required next bit = 1
	c->block[c->idx++] = 0x80;

	// pad remaining space with 0s

	// if 64 bit length will not fit
	if (c->idx > 56) {
		// pad with zero and process this will create an extra
		// block with only the 64 bit length
		memset(&(c->block[c->idx]), 0, SHA1BlockSize-c->idx);
		sha1_process(c);
	}

	// clear remaining space and set length
	memset(&(c->block[c->idx]), 0, SHA1BlockSize-c->idx);

    // length as defined in FIPS 180 is a 64 bit length
	// this implementation is limited to a 32 bit length
	c->block[60] = c->length >> 24;
	c->block[61] = c->length >> 16;
	c->block[62] = c->length >> 8;
	c->block[63] = c->length;

	sha1_process(c);

	// convert hash from uint32_ts to bytes with appropriate bytes swap
	for(cnt = 0; cnt < SHA1HashSize; cnt++){
		hash[cnt] = c->hash[cnt>>2] >> 8 * ( 3 - ( cnt & 0x03 ) );
	}
}

int sha1_verify(uint8_t * hash1 , uint8_t * hash2) {
	int cnt;
	for(cnt = 0; cnt < SHA1HashSize; cnt++)
		if (hash1[cnt] != hash2[cnt]) return -1;
	return 0;
}

#ifdef SHATEST

/*
 * Process block of data to produce SHA1 Hash
 * This is not a stream interface. All data must be passed at once.
 */
int sha1( uint8_t  *bytes, uint32_t length, uint8_t *hash)
{

    int cnt;

    SHA1Context_t context;

    // test length in bits to make sure that it will fit
    if (length * 8 > INT32_MAX) {
    	return -1;
    }

    sha1_init(&context);

    sha1_update(&context,bytes,length);

    sha1_finish(&context,hash);

    return 0;
}



/*
 *  Define patterns for testing
 */
#define numTests 5
char *testarray[numTests] =
{
		"abc",
		"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
		"",
		"The quick brown fox jumps over the lazy dog",
		"The quick brown fox jumps over the lazy cog"
};

char *resultarray[numTests] =
{
    "A9 99 3E 36 47 06 81 6A BA 3E 25 71 78 50 C2 6C 9C D0 D8 9D",
    "84 98 3E 44 1C 3B D2 6E BA AE 4A A1 F9 51 29 E5 E5 46 70 F1",
    "DA 39 A3 EE 5E 6B 4B 0D 32 55 BF EF 95 60 18 90 AF D8 07 09",
    "2F D4 E1 C6 7A 2D 28 FC ED 84 9E E1 BB 76 E7 39 1B 93 EB 12",
    "DE 9F 2C 7F D2 5E 1B 3A FA D3 E8 5A 0B D1 7D 9B 10 0D B4 B3"
};

int main()
{
    SHA1Context_t sha;
    int i, j, err;
    uint8_t HASH[20];

    /*
     *  Perform SHA-1 tests
     */
    for(j = 0; j < numTests; ++j) {
        printf( "\nTest %d: '%s'\n", j+1, testarray[j]);
    	err = sha1(testarray[j], strlen(testarray[j]), HASH);

        if (err) {
            printf("SHA1 Error %d, could not compute message digest.\n", err );
            continue;
        }
        printf("\t");
        for(i = 0; i < 20 ; ++i) {
        	printf("%02X ", HASH[i]);
        }
        printf("\n");
        printf("Should match:\n");
        printf("\t%s\n", resultarray[j]);
    }
}
#endif
