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

#import "ethernet.h"

#import <netinet/if_ether.h>

#import "ip.h"


#define ethernet_src_ptr(x)		(((struct ether_header *)(x))->ether_shost)
#define ethernet_dst_ptr(x)		(((struct ether_header *)(x))->ether_dhost)
#define ethernet_type_ptr(x)	(((struct ether_header *)(x))->ether_type)


#define ETH_TYPE(type, description, pan)	{ #type, description, pan, type }
#define ETH_TYPE_NULL						{ NULL, NULL, 0, 0 }

static const pan_header_t ethernet_types[] =
{
	ETH_TYPE(ETHERTYPE_IP,			"IPv4", &ip_input),
	ETH_TYPE(ETHERTYPE_IPV6,		"IPv6", &ip_input),
	ETH_TYPE(ETHERTYPE_ARP,			"ARP", NULL),
	ETH_TYPE(ETHERTYPE_REVARP,		"RARP", NULL),
	ETH_TYPE(ETHERTYPE_LOOPBACK,	"Loopback", NULL),
	/* XXX More ether types needed. */
	ETH_TYPE_NULL
};

#undef ETH_TYPE
#undef ETH_TYPE_NULL



int
ethernet_ptoi(const char *name)
{
	int i;
	
	for(i = 0; ethernet_types[i].name; i++)
	{
		if(strcasecmp(ethernet_types[i].name+sizeof("ETHERTYPE_")-1, name) == 0)
			return ethernet_types[i].type;
	}
	return -1;
}

const char *
ethernet_itop(int type)
{
	int i;
	
	for(i = 0; ethernet_types[i].name; i++)
	{
		if (ethernet_types[i].type == type)
			return ethernet_types[i].name+sizeof("ETHERTYPE_")-1;
	}
	return NULL;
}

pan_header_t *
ethernet_itoet(uint16_t type)
{
	int i;
	
	for(i = 0; ethernet_types[i].name; i++)
	{
		if(ethernet_types[i].type == type)
			return (voidPtr)&ethernet_types[i];
	}
	return NULL;
}

pan_header_t *
ethernet_ptoet(const u_char *data)
{
	uint16_t type = ethernet_type_ptr(data);
	type = ntohs(type);
	return ethernet_itoet(type);
}


NSString *
ethernet_host_string(const u_char *data)
{
	char addr[ETHER_ADDR_LEN*3]; /* 0 padded bytes + colons */
	
	snprintf(addr, sizeof(addr), "%02x:%02x:%02x:%02x:%02x:%02x",
			 data[0], data[1], data[2], data[3], data[4], data[5]);
	
	return [NSString stringWithUTF8String:addr];
}

NSString *
ethernet_type_string(const u_char *type)
{
	pan_header_t *e;
	if(!(e = ethernet_itoet(*type)))
		return PAN_UNKNOWN;
	
	return [NSString stringWithUTF8String:e->name];
}


/*
 * Processor methods.
 */

void
ethernet_src_string(pbuf_t *pbuf)
{
	pbuf->obj = ethernet_host_string(ethernet_src_ptr(pbuf->data));
}

void
ethernet_dst_string(pbuf_t *pbuf)
{
	pbuf->obj = ethernet_host_string(ethernet_dst_ptr(pbuf->data));
}

void
ethernet_proto_string(pbuf_t *pbuf)
{
	pbuf->obj = @"Ethernet";
}

void
ethernet_info_string(pbuf_t *pbuf)
{
	NSString *str = [NSString stringWithFormat:@"Ether Type: Unknown <0x%04x>",
					 ntohs(ethernet_type_ptr(pbuf->data))];
	pbuf->obj = str;
}

void
ethernet_input(pbuf_t *pbuf)
{
	switch(pbuf->req)
	{
		case PAN_SRC_STRING:
			ethernet_src_string(pbuf);
			break;
			
		case PAN_DST_STRING:
			ethernet_dst_string(pbuf);
			break;
			
		case PAN_PROTO_STRING:
			ethernet_proto_string(pbuf);
			break;
			
		case PAN_INFO_STRING:
			ethernet_info_string(pbuf);
			break;
	}
	pan_header_t *e = ethernet_itoet(ntohs(ethernet_type_ptr(pbuf->data)));
	PAN_NEXT(pbuf, e, ETHERNET_SIZE)
}
