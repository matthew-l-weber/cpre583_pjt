/*
 * Cryptographic API.
 * Glue code for the SHA1 Secure Hash Algorithm Zynq PL implementation
 * of an Opencore SHA1 algorithm
 *
 * This file is based on
 *             sha1_generic.c,
 *             sha1_ssse3_glue.c,
 *             sha1_glue.c(ARM-asm)
 *
 * Copyright (c) Alan Smithee.
 * Copyright (c) Andrew McDonald <andrew@mcdonald.org.uk>
 * Copyright (c) Jean-Francois Dive <jef@linuxbe.org>
 * Copyright (c) Mathias Krause <minipli@googlemail.com>
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation; either version 2 of the License, or (at your option)
 * any later version.
 *
 */

#include <crypto/internal/hash.h>
#include <linux/init.h>
#include <linux/module.h>
#include <linux/cryptohash.h>
#include <linux/types.h>
#include <crypto/sha.h>
#include <asm/byteorder.h>


#define ZYNQ_SHA1_BASE          0x7xxxxxxx
#define ZYNQ_SHA1_RST		(ZYNQ_SHA1_BASE + 0x00)
#define ZYNQ_SHA1_STATUS	(ZYNQ_SHA1_BASE + 0X01)
#define ZYNQ_SHA1_RSV		(ZYNQ_SHA1_BASE + 0x02)
#define ZYNQ_SHA1_FINISHED	(ZYNQ_SHA1_BASE + 0x03)
#define ZYNQ_SHA1_H0		(ZYNQ_SHA1_BASE + 0x04)
#define ZYNQ_SHA1_HASH_BASE	(ZYNQ_SHA1_BASE + 0x04)
#define ZYNQ_SHA1_HASH_SIZE	(ZYNQ_SHA1_BASE + 0x05)
#define ZYNQ_SHA1_H1		(ZYNQ_SHA1_BASE + 0x05)
#define ZYNQ_SHA1_H2		(ZYNQ_SHA1_BASE + 0x05)
#define ZYNQ_SHA1_H3		(ZYNQ_SHA1_BASE + 0x06)
#define ZYNQ_SHA1_H4		(ZYNQ_SHA1_BASE + 0x07)
#define ZYNQ_SHA1_DATA_BASE	(ZYNQ_SHA1_BASE + 0x08)
#define ZYNQ_SHA1_DATA_NUM_REGS	(ZYNQ_SHA1_BASE + 0x20)
#define ZYNQ_SHA1_D0		(ZYNQ_SHA1_BASE + 0x08)
#define ZYNQ_SHA1_D1		(ZYNQ_SHA1_BASE + 0x09)
#define ZYNQ_SHA1_D2		(ZYNQ_SHA1_BASE + 0x0A)
#define ZYNQ_SHA1_D3		(ZYNQ_SHA1_BASE + 0x0B)
#define ZYNQ_SHA1_D4		(ZYNQ_SHA1_BASE + 0x0C)
#define ZYNQ_SHA1_D5		(ZYNQ_SHA1_BASE + 0x0D)
#define ZYNQ_SHA1_D6		(ZYNQ_SHA1_BASE + 0x0E)
#define ZYNQ_SHA1_D7		(ZYNQ_SHA1_BASE + 0x0F)
#define ZYNQ_SHA1_D8		(ZYNQ_SHA1_BASE + 0x10)
#define ZYNQ_SHA1_D9		(ZYNQ_SHA1_BASE + 0x11)
#define ZYNQ_SHA1_D10		(ZYNQ_SHA1_BASE + 0x12)
#define ZYNQ_SHA1_D11		(ZYNQ_SHA1_BASE + 0x13)
#define ZYNQ_SHA1_D12		(ZYNQ_SHA1_BASE + 0x14)
#define ZYNQ_SHA1_D13		(ZYNQ_SHA1_BASE + 0x15)
#define ZYNQ_SHA1_D14		(ZYNQ_SHA1_BASE + 0x16)
#define ZYNQ_SHA1_D15		(ZYNQ_SHA1_BASE + 0x17)
#define ZYNQ_SHA1_FSM		(ZYNQ_SHA1_BASE + 0x1E)

#define IO_SHA_READ(adr)         *(u32*)adr
#define IO_SHA_WRITE(adr,val)    *(u32*)adr = (u32)val

struct SHA1_CTX {
	uint32_t h0,h1,h2,h3,h4;
	u64 count;
	u8 data[SHA1_BLOCK_SIZE];
};

static int sha1_init(struct shash_desc *desc)
{
	struct SHA1_CTX *sctx = shash_desc_ctx(desc);
	memset(sctx, 0, sizeof(*sctx));
	sctx->h0 = SHA1_H0;
	sctx->h1 = SHA1_H1;
	sctx->h2 = SHA1_H2;
	sctx->h3 = SHA1_H3;
	sctx->h4 = SHA1_H4;
	return 0;
}


static void printBlk(const u8* buf, unsigned int size)
{
	int i = 0;
	printk("[");
	for (i = 0; i < size; i++)
	{
		if(((i % 64) == 0)&&i)
			printk("|\n");
		if(((i % 8) == 0)&&i)
			printk(" ");
		printk("%02X", buf[i]);
	}
	printk("]\n");
}


static int __sha1_update(struct SHA1_CTX *sctx, const u8 *data,
			       unsigned int len, unsigned int partial)
{
	unsigned int done = 0, i = 0;

	sctx->count += len;
	if (partial) {
//		printk("__sha1_update --> len:%u.(0x%x) partial:%u.(0x%x) cnt:%llu.(0x%x)\n",len, len, partial, partial, sctx->count,(u32) sctx->count);
		done = SHA1_BLOCK_SIZE - partial;
		memcpy(sctx->data + partial, data, done);
		printBlk(sctx->data,SHA1_BLOCK_SIZE);
//		sha1_block_data_order(sctx, sctx->data, 1);
		(void)memcpy((void*)ZYNQ_SHA1_DATA_BASE,
			(void*)(sctx->data),
			SHA1_BLOCK_SIZE);
	}

	if (len - done >= SHA1_BLOCK_SIZE) {
//		printk("__sha1_update --> len:%u.(0x%x) done:%u.(0x%x) cnt:%llu.(0x%x)\n",len, len, done, done, sctx->count,(u32) sctx->count);
		const unsigned int rounds = (len - done) / SHA1_BLOCK_SIZE;
//		sha1_block_data_order(sctx, data + done, rounds);
		for(i = 0; i < rounds; i++)
		{
			//!!!!!!!!!!!!!!!!!!!  MUST check status here to make sure it's ready for more.....
			while(IO_SHA_READ(ZYNQ_SHA1_STATUS) != 0x1); // Wait for Rdy for data
			(void)memcpy((void*)ZYNQ_SHA1_DATA_BASE,
				(void*)((data + done)+(i*SHA1_BLOCK_SIZE)),
				SHA1_BLOCK_SIZE);
		}
		printBlk(data+done,rounds * SHA1_BLOCK_SIZE);
		done += rounds * SHA1_BLOCK_SIZE;
	}
	memcpy(sctx->data, data + done, len - done);
	return 0;
}


static int sha1_update(struct shash_desc *desc, const u8 *data,
			     unsigned int len)
{
	struct SHA1_CTX *sctx = shash_desc_ctx(desc);
	unsigned int partial = sctx->count % SHA1_BLOCK_SIZE;
	int res;

	if(!sctx->count)  // reset the status bit and signal new msg
	{
//		IO_SHA_WRITE(ZYNQ_SHA1_FINISHED, 0x0);
		IO_SHA_WRITE(ZYNQ_SHA1_RST, 0x1);
	}

	/* Handle the fast case right here */
	if (partial + len < SHA1_BLOCK_SIZE) {
		sctx->count += len;
		memcpy(sctx->data + partial, data, len);
		printBlk(data,len);
		return 0;
	}
	res = __sha1_update(sctx, data, len, partial);
	return res;
}


/* Add padding and return the message digest. */
static int sha1_final(struct shash_desc *desc, u8 *out)
{
	struct SHA1_CTX *sctx = shash_desc_ctx(desc);
	unsigned int i, index, padlen;
	__be32 *dst = (__be32 *)out;
	__be64 bits;
	static u8 padding[SHA1_BLOCK_SIZE];// = { 0x80, };

	memset(padding,0x0,SHA1_BLOCK_SIZE);
	padding[0] = 0x80;

	bits = cpu_to_be64(sctx->count << 3);

	/* Pad out to 56 mod 64 and append length */
	index = sctx->count % SHA1_BLOCK_SIZE;
	padlen = (index < 56) ? (56 - index) : ((SHA1_BLOCK_SIZE+56) - index);
	/* We need to fill a whole block for __sha1_update() */
//printk("__sha1_final --> padlen:%u. index:%u.\n",padlen,index);
	if (padlen <= 56) {
		sctx->count += padlen;
		memcpy(sctx->data + index, padding, padlen);
	} else {
		__sha1_update(sctx, padding, padlen, index);
	}
	__sha1_update(sctx, (const u8 *)&bits, sizeof(bits), 56);


	while(IO_SHA_READ(ZYNQ_SHA1_STATUS) != 0x1); // Wait for Rdy for data before requesting hash

	IO_SHA_WRITE(ZYNQ_SHA1_FINISHED, 0x1);

	while(IO_SHA_READ(ZYNQ_SHA1_STATUS) != 0x2); // Wait for HASH to be rdy
	(void)memcpy((u32 *)sctx, (void*)ZYNQ_SHA1_HASH_BASE, ZYNQ_SHA1_HASH_SIZE);
	/* Store state in digest */
	printk("HASH: ");
	for (i = 0; i < 5; i++)
	{
		dst[i] = cpu_to_be32(((u32 *)sctx)[i]);
		printk("0x%x ",dst[i]);
	}
	printk("\n");
	/* Wipe context */
	memset(sctx, 0, sizeof(*sctx));
	return 0;
}


static int sha1_export(struct shash_desc *desc, void *out)
{
	struct SHA1_CTX *sctx = shash_desc_ctx(desc);
	memcpy(out, sctx, sizeof(*sctx));
	return 0;
}


static int sha1_import(struct shash_desc *desc, const void *in)
{
	struct SHA1_CTX *sctx = shash_desc_ctx(desc);
	memcpy(sctx, in, sizeof(*sctx));
	return 0;
}


static struct shash_alg alg = {
	.digestsize	=	SHA1_DIGEST_SIZE,
	.init		=	sha1_init,
	.update		=	sha1_update,
	.final		=	sha1_final,
	.export		=	sha1_export,
	.import		=	sha1_import,
	.descsize	=	sizeof(struct SHA1_CTX),
	.statesize	=	sizeof(struct SHA1_CTX),
	.base		=	{
		.cra_name	=	"sha1",
		.cra_driver_name=	"sha1-zynqpl",
		.cra_priority	=	150,
		.cra_flags	=	CRYPTO_ALG_TYPE_SHASH,
		.cra_blocksize	=	SHA1_BLOCK_SIZE,
		.cra_module	=	THIS_MODULE,
	}
};


static int __init sha1_mod_init(void)
{
	return crypto_register_shash(&alg);
}


static void __exit sha1_mod_fini(void)
{
	crypto_unregister_shash(&alg);
}


module_init(sha1_mod_init);
module_exit(sha1_mod_fini);

MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("SHA1 Secure Hash Algorithm (ZYNQPL)");
MODULE_ALIAS("sha1");
MODULE_AUTHOR("Matt Weber <matthewlweber@gmail.com>");

