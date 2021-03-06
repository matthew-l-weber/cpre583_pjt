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
 * Copyright (c) Matthew L Weber <mlweber@iastate.edu>
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
#include <linux/delay.h>
#include <crypto/sha.h>
#include <asm/byteorder.h>


//#define DEBUG_SHA  1

static void *memPtr;

#define ZYNQ_SHA1_BASE		0x7AA00000
#define ZYNQ_SHA1_REGION_SIZE	0x00000080

#define ZYNQ_SHA1_RST		0x00
#define ZYNQ_SHA1_STATUS	0x04
#define ZYNQ_SHA1_STARTBLK	0x08
#define ZYNQ_SHA1_FINISHED	0x0C
#define ZYNQ_SHA1_H0		0x10
#define ZYNQ_SHA1_HASH_BASE	0x10
#define ZYNQ_SHA1_HASH_SIZE	0x14
#define ZYNQ_SHA1_H1		0x14
#define ZYNQ_SHA1_H2		0x18
#define ZYNQ_SHA1_H3		0x1C
#define ZYNQ_SHA1_H4		0x20
#define ZYNQ_SHA1_DATA_BASE	0x24
#define ZYNQ_SHA1_DATA_NUM_REGS	0x20
#define ZYNQ_SHA1_D0		0x24
#define ZYNQ_SHA1_D1		0x28
#define ZYNQ_SHA1_D2		0x2C
#define ZYNQ_SHA1_D3		0x30
#define ZYNQ_SHA1_D4		0x34
#define ZYNQ_SHA1_D5		0x38
#define ZYNQ_SHA1_D6		0x3C
#define ZYNQ_SHA1_D7		0x40
#define ZYNQ_SHA1_D8		0x44
#define ZYNQ_SHA1_D9		0x48
#define ZYNQ_SHA1_D10		0x4C
#define ZYNQ_SHA1_D11		0x50
#define ZYNQ_SHA1_D12		0x54
#define ZYNQ_SHA1_D13		0x58
#define ZYNQ_SHA1_D14		0x5C
#define ZYNQ_SHA1_D15		0x60
// .....
#define ZYNQ_SHA1_FSM		0x78

#define IO_SHA_READ(offset)         ioread32(memPtr + offset)
#define IO_SHA_WRITE(offset, val)   iowrite32((u32)val, memPtr + offset)


#define HASH_RDY   0x2
#define INPUT_RDY  0x1
#define HASH_BUSY  0x4

#define NEW_HASH   0x1
#define CONT_HASH  0x2

struct SHA1_CTX {
	uint32_t h0,h1,h2,h3,h4;
	u64 count;
	u8 data[SHA1_BLOCK_SIZE];
	u32 algoCMD;
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

static void printAlgoState(void)
{
	unsigned int currentStatus = IO_SHA_READ(ZYNQ_SHA1_STATUS);
	printk("SHA1 Status[");
	if(currentStatus & INPUT_RDY)
		printk("INPUT_RDY ");
	if(currentStatus & HASH_RDY)
		printk("HASH_RDY ");
	if(currentStatus & HASH_BUSY)
		printk("HASH_BUSY ");
	printk("]\n");	
}

static int __sha1_update(struct SHA1_CTX *sctx, const u8 *data,
			       unsigned int len, unsigned int partial)
{
	unsigned int done = 0, i = 0, j = 0;
	unsigned int rounds = 0;

	sctx->count += len;
	if (partial) {
#ifdef DEBUG_SHA
		printk("__sha1_update --> len:%u.(0x%x) partial:%u.(0x%x) cnt:%llu.(0x%x)\n",
			len, len, partial, partial, sctx->count,(u32) sctx->count);
#endif
		done = SHA1_BLOCK_SIZE - partial;
		memcpy(sctx->data + partial, data, done);
#ifdef DEBUG_SHA
		printBlk(sctx->data,SHA1_BLOCK_SIZE);
#endif
		// MUST check status here to make sure it's ready for more.....
		while(!(IO_SHA_READ(ZYNQ_SHA1_STATUS) & INPUT_RDY))
		{
#ifdef DEBUG_SHA
			printAlgoState();
			msleep(100);
#endif
		}

		for(i = 0; i < SHA1_BLOCK_SIZE /4; i++) //HACK
			((u32*)(sctx->data))[i] = cpu_to_be32(((u32*)(sctx->data))[i]); //HACK
		(void)memcpy_toio(
			(u32*)(memPtr+ZYNQ_SHA1_DATA_BASE),
			(u32*)(sctx->data),
			SHA1_BLOCK_SIZE);
#ifdef DEBUG_SHA
printk("algoCMD1 0x%x  0x%08x\n",sctx->algoCMD,IO_SHA_READ(ZYNQ_SHA1_D0));
#endif
		IO_SHA_WRITE(ZYNQ_SHA1_RST, sctx->algoCMD); 
		sctx->algoCMD = CONT_HASH;
	}

	if (len - done >= SHA1_BLOCK_SIZE) {
#ifdef DEBUG_SHA
		printk("__sha1_update --> len:%u.(0x%x) done:%u.(0x%x) cnt:%llu.(0x%x)\n",
			len, len, done, done, sctx->count,(u32) sctx->count);
#endif
		rounds = (len - done) / SHA1_BLOCK_SIZE;
		for(i = 0; i < rounds; i++)
		{
			while(!(IO_SHA_READ(ZYNQ_SHA1_STATUS) & INPUT_RDY))
			{
#ifdef DEBUG_SHA
				printAlgoState();
				msleep(100);
#endif
			}
			for(j = 0; j < SHA1_BLOCK_SIZE /4; j++) //HACK
				((u32*)((data + done)+(i*SHA1_BLOCK_SIZE)))[j] = 
					cpu_to_be32(((u32*)((data + done)+(i*SHA1_BLOCK_SIZE)))[j]); //HACK
			(void)memcpy_toio(
				(u32*)(memPtr+ZYNQ_SHA1_DATA_BASE),
				(u32*)((data + done)+(i*SHA1_BLOCK_SIZE)),
				SHA1_BLOCK_SIZE);
#ifdef DEBUG_SHA
printk("algoCMD2 0x%x  0x%08x\n",sctx->algoCMD,IO_SHA_READ(ZYNQ_SHA1_D0));
#endif
			IO_SHA_WRITE(ZYNQ_SHA1_RST, sctx->algoCMD); 
			sctx->algoCMD = CONT_HASH;
		}
#ifdef DEBUG_SHA
		printBlk(data+done,rounds * SHA1_BLOCK_SIZE);
#endif
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
		sctx->algoCMD = NEW_HASH;
	}		

	/* Handle the fast case right here */
	if (partial + len < SHA1_BLOCK_SIZE) {
		sctx->count += len;
		memcpy(sctx->data + partial, data, len);
#ifdef DEBUG_SHA
		printBlk(data,len);
#endif
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
#ifdef DEBUG_SHA
	printk("__sha1_final --> padlen:%u. index:%u.\n",padlen,index);
#endif
	if (padlen <= 56) {
		sctx->count += padlen;
		memcpy(sctx->data + index, padding, padlen);
	} else {
		__sha1_update(sctx, padding, padlen, index);
	}
	__sha1_update(sctx, (const u8 *)&bits, sizeof(bits), 56);

	while((IO_SHA_READ(ZYNQ_SHA1_STATUS) & HASH_BUSY))
	{
#ifdef DEBUG_SHA
		printAlgoState();
		msleep(100);
#endif
	}
	(void)memcpy_fromio(
		(u32 *)sctx, 
		(u32*)(memPtr+ZYNQ_SHA1_HASH_BASE), 
		ZYNQ_SHA1_HASH_SIZE);
	/* Store state in digest */
	printk("HASH: ");
	for (i = 0; i < 5; i++)
	{
		dst[i] = ((u32 *)sctx)[i];
//opencore already gens big endian		dst[i] = cpu_to_be32(((u32 *)sctx)[i]);
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
	if (!request_mem_region(ZYNQ_SHA1_BASE, ZYNQ_SHA1_REGION_SIZE, "zynq_sha1")) 
	{
		printk("request_mem_region failed\n");
		return -ENXIO;
	}

	memPtr = ioremap(ZYNQ_SHA1_BASE, ZYNQ_SHA1_REGION_SIZE);
	if(memPtr == NULL)
	{
		printk("I/O remap failed\n");
		release_mem_region(ZYNQ_SHA1_BASE, ZYNQ_SHA1_REGION_SIZE);
		return -ENOMEM;
	}
	printk("Mapped 0x%x \n",(u32)memPtr);
	printAlgoState();

	return crypto_register_shash(&alg);
}


static void __exit sha1_mod_fini(void)
{
	crypto_unregister_shash(&alg);
	iounmap(memPtr);
	release_mem_region(ZYNQ_SHA1_BASE, ZYNQ_SHA1_REGION_SIZE);
}


module_init(sha1_mod_init);
module_exit(sha1_mod_fini);

MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("SHA1 Secure Hash Algorithm (ZYNQPL)");
MODULE_ALIAS("sha1");
MODULE_AUTHOR("Matt Weber <matthewlweber@gmail.com>");

