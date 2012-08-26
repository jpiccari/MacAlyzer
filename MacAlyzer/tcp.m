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

#import "tcp.h"

#import <netinet/tcp.h>

#define TCP_PORT_SEP	":"

#define TCPFLAG_CWR		"CWR"
#define TCPFLAG_ECE		"ECE"
#define TCPFLAG_URG		"URG"
#define TCPFLAG_ACK		"ACK"
#define TCPFLAG_PSH		"PSH"
#define TCPFLAG_RST		"RST"
#define TCPFLAG_SYN		"SYN"
#define TCPFLAG_FIN		"FIN"

/*
 * Processor methods.
 */

void
tcp_src_string(pbuf_t *pbuf)
{
	pbuf->obj =
	[NSString stringWithFormat:@"%@%s%u",
	 pbuf->obj, TCP_PORT_SEP, htons(((struct tcphdr *)pbuf->data)->th_sport)];
}

void
tcp_dst_string(pbuf_t *pbuf)
{
	pbuf->obj =
	[NSString stringWithFormat:@"%@%s%hu",
	 pbuf->obj, TCP_PORT_SEP, htons(((struct tcphdr *)pbuf->data)->th_dport)];
}

void
tcp_proto_string(pbuf_t *pbuf)
{
	pbuf->obj = @"TCP";
}

void
tcp_info_string(pbuf_t *pbuf)
{
	BOOL _flag = YES;
	struct tcphdr *hdr = (struct tcphdr *)pbuf->data;
	uint8_t flags = hdr->th_flags;
	NSMutableString *str = [NSMutableString stringWithFormat:@"%hu > %hu ",
							htons(hdr->th_sport), htons(hdr->th_dport)];
	
#define FLAGS_APPEND(a, b, flag)							\
	if(flag) {												\
		flag = NO;											\
		[(NSMutableString *)b appendFormat:@"[%s", a];		\
	}														\
	else													\
		[(NSMutableString *)b appendFormat:@", %s", a];
	
	if(flags & TH_CWR)
		FLAGS_APPEND(TCPFLAG_CWR, str, _flag);
	if(flags & TH_ECE)
		FLAGS_APPEND(TCPFLAG_ECE, str, _flag);
	if(flags & TH_URG)
		FLAGS_APPEND(TCPFLAG_URG, str, _flag);
	if(flags & TH_ACK)
		FLAGS_APPEND(TCPFLAG_ACK, str, _flag);
	if(flags & TH_PUSH)
		FLAGS_APPEND(TCPFLAG_PSH, str, _flag);
	if(flags & TH_RST)
		FLAGS_APPEND(TCPFLAG_RST, str, _flag);
	if(flags & TH_SYN)
		FLAGS_APPEND(TCPFLAG_SYN, str, _flag);
	if(flags & TH_FIN)
		FLAGS_APPEND(TCPFLAG_FIN, str, _flag);
	
#undef FLAGS_APPEND
	
	[str appendFormat:@"] "];
	
	pbuf->obj = str;
}


void
tcp_input(pbuf_t *pbuf)
{
	switch(pbuf->req)
	{
		case PAN_SRC_STRING:
			tcp_src_string(pbuf);
			break;
			
		case PAN_DST_STRING:
			tcp_dst_string(pbuf);
			break;
			
		case PAN_PROTO_STRING:
			tcp_proto_string(pbuf);
			break;
			
		case PAN_INFO_STRING:
			tcp_info_string(pbuf);
			break;
	}
}
