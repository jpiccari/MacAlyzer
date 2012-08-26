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

#import "ip.h"

#import <arpa/inet.h>
#import <netinet/ip.h>
#import <netinet/ip6.h>

#import "icmp.h"
#import "icmp6.h"
#import "tcp.h"
#import "udp.h"


#define ip_ver(x)		((((uint8_t)(*x)) & IPV6_VERSION_MASK) >> 4)
#define ip_isLegacy(x)	(ip_ver(x) == IPVERSION)


#define IP_PROTO(proto, description, pan)	{ #proto, description, pan, proto }
#define IP_PROTO_NULL						{ NULL, NULL, 0, 0 }

static const pan_header_t ip_protos[] =
{
	/* XXX More ip protos needed. */
	IP_PROTO(IPPROTO_IPV4, "IPv4 (encapsulation)", &ip_input),
	IP_PROTO(IPPROTO_IPV6, "IPv6 (encapsulation)", &ip_input),
	
	IP_PROTO(IPPROTO_TCP, "Transmission Control Protocol", &tcp_input),
	IP_PROTO(IPPROTO_UDP, "User Datagram Protocol", &udp_input),
	IP_PROTO(IPPROTO_ICMP, "Internet Control Message Protocol", &icmp_input),
	IP_PROTO(IPPROTO_ICMPV6, "Internet Control Message Protocol v6", &icmp6_input),
	IP_PROTO(IPPROTO_SCTP, "Stream Control Transmission Protocol", NULL),
	IP_PROTO(IPPROTO_DCCP, "Datagram Congestion Control Protocol", NULL),
	IP_PROTO_NULL
};

#undef IP_PROTO
#undef IP_PROTO_NULL


pan_header_t *
ip_itoet(uint8_t proto)
{
	int i;
	
	for(i = 0; ip_protos[i].name; i++)
	{
		if(ip_protos[i].type == proto)
			return (voidPtr)&ip_protos[i];
	}
	return NULL;
}

pan_header_t *
ip_ptoet(const u_char *data)
{
	uint8_t proto;
	
	if(ip_isLegacy(data))
		proto = ((struct ip *)data)->ip_p;
	else
		proto = ((struct ip6_hdr *)data)->ip6_nxt;
	
	return ip_itoet(proto);
}


NSString *
ip_host_string(BOOL legacy, const u_char *data)
{
	char addr[INET6_ADDRSTRLEN];
	
	if(legacy)
		inet_ntop(AF_INET, data, addr, INET_ADDRSTRLEN);
	else
		inet_ntop(AF_INET6, data, addr, INET6_ADDRSTRLEN);
	
	return [NSString stringWithUTF8String:addr];
}

uint16_t
ip_header_len(const u_char *data)
{
	if(ip_isLegacy(data))
		return ((struct ip *)data)->ip_hl*32/8;
	
	return sizeof(struct ip6_hdr); /* IPv6 has a fixed header sizem, yay. */
}



/*
 * Processor methods.
 */

void
ip_src_string(pbuf_t *pbuf)
{
	if(ip_isLegacy(pbuf->data))
		pbuf->obj = ip_host_string(YES, (voidPtr)&((struct ip *)pbuf->data)->ip_src);
	else
		pbuf->obj = ip_host_string(NO, (voidPtr)&((struct ip6_hdr *)pbuf->data)->ip6_src);
}

void
ip_dst_string(pbuf_t *pbuf)
{
	if(ip_isLegacy(pbuf->data))
		pbuf->obj = ip_host_string(YES, (voidPtr)&((struct ip *)pbuf->data)->ip_dst);
	else
		pbuf->obj = ip_host_string(NO, (voidPtr)&((struct ip6_hdr *)pbuf->data)->ip6_dst);
}

void
ip_proto_string(pbuf_t *pbuf)
{
	if(ip_isLegacy(pbuf->data))
		pbuf->obj = @"IPv4";
	else
		pbuf->obj = @"IPv6";
}

void
ip_info_string(pbuf_t *pbuf)
{
	if(ip_isLegacy(pbuf->data))
	{
		pbuf->obj =
		[NSString stringWithFormat:@"Payload: %u bytes",
		 ((struct ip *)pbuf->data)->ip_len-ip_header_len(pbuf->data)];
	}
	else
	{
		pbuf->obj =
		[NSString stringWithFormat:@"Payload: %u bytes",
		 ((struct ip6_hdr *)pbuf->data)->ip6_plen-ip_header_len(pbuf->data)];
	}
}


void
ip_input(pbuf_t *pbuf)
{
	switch(pbuf->req)
	{
		case PAN_SRC_STRING:
			ip_src_string(pbuf);
			break;
			
		case PAN_DST_STRING:
			ip_dst_string(pbuf);
			break;
			
		case PAN_PROTO_STRING:
			ip_proto_string(pbuf);
			break;
			
		case PAN_INFO_STRING:
			ip_info_string(pbuf);
			break;
	}
	
	uint8_t proto;
	if(ip_isLegacy(pbuf->data))
		proto = ((struct ip *)pbuf->data)->ip_p;
	else
		proto = ((struct ip6_hdr *)pbuf->data)->ip6_nxt;
	
	
	pan_header_t *p = ip_itoet(proto);
	uint16_t len = ip_header_len(pbuf->data);
	PAN_NEXT(pbuf, p, len)
}
