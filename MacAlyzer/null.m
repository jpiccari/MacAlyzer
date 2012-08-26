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

#include "null.h"

#import <sys/socket.h>

#import "ip.h"


#define NULL_HEADER_SIZE	4 /* Size in bytes. */

#define LOOP_TYPE(type, description, pan)	{ #type, description, pan, type }
#define LOOP_TYPE_NULL						{ NULL, NULL, 0, 0 }

static const pan_header_t null_families[] =
{
	LOOP_TYPE(AF_INET,		"IPv4", &ip_input),
	LOOP_TYPE(AF_INET6,		"IPv6", &ip_input),
	/* XXX More address families needed. */
	LOOP_TYPE_NULL
};

#undef LOOP_TYPE
#undef LOOP_TYPE_NULL


pan_header_t *
null_itop(int type)
{
	int i;
	
	/* XXX We need to be more vigerous with our search. */
	for(i = 0; null_families[i].name; i++)
	{
		if (null_families[i].type == type)
			return (voidPtr)&null_families[i];
	}
	return NULL;
}


/*
 * Processor methods.
 */

void
null_proto_string(pbuf_t *pbuf)
{
	pbuf->obj = @"Loopback";
}

void
null_info_string(pbuf_t *pbuf)
{
	pbuf->obj = [NSString stringWithFormat:@"BSD NULL (Loopback)"];
}


void
null_input(pbuf_t *pbuf)
{
	switch(pbuf->req)
	{
		case PAN_PROTO_STRING:
			null_proto_string(pbuf);
			break;
		case PAN_INFO_STRING:
			null_info_string(pbuf);
			break;
			
		default:
			break;
	}
	
	pan_header_t *af = null_itop(((uint32_t)*pbuf->data));
	PAN_NEXT(pbuf, af, NULL_HEADER_SIZE)
}

