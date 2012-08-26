/*
 * Copyright (c) 2012 Joshua Piccari, All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *
 *	This product includes software developed by Joshua Piccari
 *
 * 4. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>

#define PAN_UNKNOWN			@"<Unknown>"
#define PAN_NEXT(p, h, size)										\
	{																\
		if((p) && (h) && (h)->pan)									\
		{															\
			if((p)->len > size)										\
			{														\
				size_t pan_next_len = size;							\
				(p)->len -= pan_next_len;							\
				(p)->data += pan_next_len;							\
				((h)->pan)(p);										\
				(p)->data -= pan_next_len;							\
				(p)->len += pan_next_len;							\
			}														\
		}															\
	}																\

typedef enum
{
	PAN_SRC_STRING,
	PAN_DST_STRING,
	PAN_PROTO_STRING,
	PAN_INFO_STRING
} pan_req_t;

typedef struct
{
	int dlt;
	ssize_t len;
	pan_req_t req;
	id obj;
	const u_char *data;
} pbuf_t;

#define p_dat(p)	(p->dat+p->pos)

typedef void (*pan_t)(pbuf_t *);

typedef struct
{
	const char *name;
	const char *description;
	pan_t pan;
	int	type;
} pan_header_t;



static int pan_stoi(const char *name);
static const char *pan_itos(int type);
static pan_t pan_itop(int type);

id pan_input(pan_req_t req, int dlt, const u_char *buf, size_t len);
