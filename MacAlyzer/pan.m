/*
 * Copyright (c) 2011 Joshua Piccari, All rights reserved.
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

#import "pan.h"

#import "pan-dlt.h"
#import "ethernet.h"
#import "null.h"



#define PAN_DLT(type, description, dlt)	{ #type, description, dlt, type }
#define PAN_DLT_NULL					{ NULL, NULL, 0, 0 }

static const pan_header_t dlt_types[] =
{
	PAN_DLT(DLT_NULL, "BSD loopback", &null_input),
	PAN_DLT(DLT_EN10MB, "Ethernet", &ethernet_input),
	PAN_DLT(DLT_IEEE802, "Token ring", NULL),
	PAN_DLT(DLT_ARCNET, "BSD ARCNET", NULL),
	PAN_DLT(DLT_SLIP, "SLIP", NULL),
	PAN_DLT(DLT_PPP, "PPP", NULL),
	PAN_DLT(DLT_FDDI, "FDDI", NULL),
	PAN_DLT(DLT_ATM_RFC1483, "RFC 1483 LLC-encapsulated ATM", NULL),
	PAN_DLT(DLT_RAW, "Raw IP", NULL),
	PAN_DLT(DLT_SLIP_BSDOS, "BSD/OS SLIP", NULL),
	PAN_DLT(DLT_PPP_BSDOS, "BSD/OS PPP", NULL),
	PAN_DLT(DLT_ATM_CLIP, "Linux Classical IP-over-ATM", NULL),
	PAN_DLT(DLT_PPP_SERIAL, "PPP over serial", NULL),
	PAN_DLT(DLT_PPP_ETHER, "PPPoE", NULL),
	PAN_DLT(DLT_SYMANTEC_FIREWALL, "Symantec Firewall", NULL),
	PAN_DLT(DLT_C_HDLC, "Cisco HDLC", NULL),
	PAN_DLT(DLT_IEEE802_11, "802.11", NULL),
	PAN_DLT(DLT_FRELAY, "Frame Relay", NULL),
	PAN_DLT(DLT_LOOP, "OpenBSD loopback", NULL),
	PAN_DLT(DLT_ENC, "OpenBSD encapsulated IP", NULL),
	PAN_DLT(DLT_LINUX_SLL, "Linux cooked", NULL),
	PAN_DLT(DLT_LTALK, "Localtalk", NULL),
	PAN_DLT(DLT_PFLOG, "OpenBSD pflog file", NULL),
	PAN_DLT(DLT_PRISM_HEADER, "802.11 plus Prism header", NULL),
	PAN_DLT(DLT_IP_OVER_FC, "RFC 2625 IP-over-Fibre Channel", NULL),
	PAN_DLT(DLT_SUNATM, "Sun raw ATM", NULL),
	PAN_DLT(DLT_IEEE802_11_RADIO, "802.11 plus radiotap header", NULL),
	PAN_DLT(DLT_ARCNET_LINUX, "Linux ARCNET", NULL),
	PAN_DLT(DLT_JUNIPER_MLPPP, "Juniper Multi-Link PPP", NULL),
	PAN_DLT(DLT_JUNIPER_MLFR, "Juniper Multi-Link Frame Relay", NULL),
	PAN_DLT(DLT_JUNIPER_ES, "Juniper Encryption Services PIC", NULL),
	PAN_DLT(DLT_JUNIPER_GGSN, "Juniper GGSN PIC", NULL),
	PAN_DLT(DLT_JUNIPER_MFR, "Juniper FRF.16 Frame Relay", NULL),
	PAN_DLT(DLT_JUNIPER_ATM2, "Juniper ATM2 PIC", NULL),
	PAN_DLT(DLT_JUNIPER_SERVICES, "Juniper Advanced Services PIC", NULL),
	PAN_DLT(DLT_JUNIPER_ATM1, "Juniper ATM1 PIC", NULL),
	PAN_DLT(DLT_APPLE_IP_OVER_IEEE1394, "Apple IP-over-IEEE 1394", NULL),
	PAN_DLT(DLT_MTP2_WITH_PHDR, "SS7 MTP2 with Pseudo-header", NULL),
	PAN_DLT(DLT_MTP2, "SS7 MTP2", NULL),
	PAN_DLT(DLT_MTP3, "SS7 MTP3", NULL),
	PAN_DLT(DLT_SCCP, "SS7 SCCP", NULL),
	PAN_DLT(DLT_DOCSIS, "DOCSIS", NULL),
	PAN_DLT(DLT_LINUX_IRDA, "Linux IrDA", NULL),
	PAN_DLT(DLT_IEEE802_11_RADIO_AVS, "802.11 plus AVS radio information header", NULL),
	PAN_DLT(DLT_JUNIPER_MONITOR, "Juniper Passive Monitor PIC", NULL),
	PAN_DLT(DLT_PPP_PPPD, "PPP for pppd, with direction flag", NULL),
	PAN_DLT(DLT_JUNIPER_PPPOE, "Juniper PPPoE", NULL),
	PAN_DLT(DLT_JUNIPER_PPPOE_ATM, "Juniper PPPoE/ATM", NULL),
	PAN_DLT(DLT_GPRS_LLC, "GPRS LLC", NULL),
	PAN_DLT(DLT_GPF_T, "GPF-T", NULL),
	PAN_DLT(DLT_GPF_F, "GPF-F", NULL),
	PAN_DLT(DLT_JUNIPER_PIC_PEER, "Juniper PIC Peer", NULL),
	PAN_DLT(DLT_ERF_ETH,	"Ethernet with Endace ERF header", NULL),
	PAN_DLT(DLT_ERF_POS, "Packet-over-SONET with Endace ERF header", NULL),
	PAN_DLT(DLT_LINUX_LAPD, "Linux vISDN LAPD", NULL),
	PAN_DLT(DLT_JUNIPER_ETHER, "Juniper Ethernet", NULL),
	PAN_DLT(DLT_JUNIPER_PPP, "Juniper PPP", NULL),
	PAN_DLT(DLT_JUNIPER_FRELAY, "Juniper Frame Relay", NULL),
	PAN_DLT(DLT_JUNIPER_CHDLC, "Juniper C-HDLC", NULL),
	PAN_DLT(DLT_MFR, "FRF.16 Frame Relay", NULL),
	PAN_DLT(DLT_JUNIPER_VP, "Juniper Voice PIC", NULL),
	PAN_DLT(DLT_A429, "Arinc 429", NULL),
	PAN_DLT(DLT_A653_ICM, "Arinc 653 Interpartition Communication", NULL),
	PAN_DLT(DLT_USB, "USB", NULL),
	PAN_DLT(DLT_BLUETOOTH_HCI_H4, "Bluetooth HCI UART transport layer", NULL),
	PAN_DLT(DLT_IEEE802_16_MAC_CPS, "IEEE 802.16 MAC Common Part Sublayer", NULL),
	PAN_DLT(DLT_USB_LINUX, "USB with Linux header", NULL),
	PAN_DLT(DLT_CAN20B, "Controller Area Network (CAN) v. 2.0B", NULL),
	PAN_DLT(DLT_IEEE802_15_4_LINUX, "IEEE 802.15.4 with Linux padding", NULL),
	PAN_DLT(DLT_PPI, "Per-Packet Information", NULL),
	PAN_DLT(DLT_IEEE802_16_MAC_CPS_RADIO, "IEEE 802.16 MAC Common Part Sublayer plus radiotap header", NULL),
	PAN_DLT(DLT_JUNIPER_ISM, "Juniper Integrated Service Module", NULL),
	PAN_DLT(DLT_IEEE802_15_4, "IEEE 802.15.4 with FCS", NULL),
	PAN_DLT(DLT_SITA, "SITA pseudo-header", NULL),
	PAN_DLT(DLT_ERF, "Endace ERF header", NULL),
	PAN_DLT(DLT_RAIF1, "Ethernet with u10 Networks pseudo-header", NULL),
	PAN_DLT(DLT_IPMB, "IPMB", NULL),
	PAN_DLT(DLT_JUNIPER_ST, "Juniper Secure Tunnel", NULL),
	PAN_DLT(DLT_BLUETOOTH_HCI_H4_WITH_PHDR, "Bluetooth HCI UART transport layer plus pseudo-header", NULL),
	PAN_DLT(DLT_AX25_KISS, "AX.25 with KISS header", NULL),
	PAN_DLT(DLT_IEEE802_15_4_NONASK_PHY, "IEEE 802.15.4 with non-ASK PHY data", NULL),
	PAN_DLT(DLT_MPLS, "MPLS with label as link-layer header", NULL),
	PAN_DLT(DLT_USB_LINUX_MMAPPED, "USB with padded Linux header", NULL),
	PAN_DLT(DLT_DECT, "DECT", NULL),
	PAN_DLT(DLT_AOS, "AOS Space Data Link protocol", NULL),
	PAN_DLT(DLT_WIHART, "Wireless HART", NULL),
	PAN_DLT(DLT_FC_2, "Fibre Channel FC-2", NULL),
	PAN_DLT(DLT_FC_2_WITH_FRAME_DELIMS, "Fibre Channel FC-2 with frame delimiters", NULL),
	PAN_DLT(DLT_IPNET, "Solaris ipnet", NULL),
	PAN_DLT(DLT_CAN_SOCKETCAN, "CAN-bus with SocketCAN headers", NULL),
	PAN_DLT(DLT_IPV4, "Raw IPv4", NULL),
	PAN_DLT(DLT_IPV6, "Raw IPv6", NULL),
	PAN_DLT(DLT_IEEE802_15_4_NOFCS, "IEEE 802.15.4 without FCS", NULL),
	PAN_DLT(DLT_JUNIPER_VS, "Juniper Virtual Server", NULL),
	PAN_DLT(DLT_JUNIPER_SRX_E2E, "Juniper SRX E2E", NULL),
	PAN_DLT(DLT_JUNIPER_FIBRECHANNEL, "Juniper Fibrechannel", NULL),
	PAN_DLT(DLT_DVB_CI, "DVB-CI", NULL),
	PAN_DLT(DLT_JUNIPER_ATM_CEMIC, "Juniper ATM CEMIC", NULL),
	PAN_DLT_NULL
};

#undef PAN_DLT
#undef PAN_DLT_NULL


static int
pan_stoi(const char *name)
{
	int i;
	
	for(i = 0; dlt_types[i].name; i++)
	{
		if(strcasecmp(dlt_types[i].name+sizeof("DLT_")-1, name) == 0)
			return dlt_types[i].type;
	}
	return -1;
}

static const char *
pan_itos(int type)
{
	int i;
	
	for(i = 0; dlt_types[i].name; i++)
	{
		if (dlt_types[i].type == type)
			return dlt_types[i].name+sizeof("DLT_")-1;
	}
	return NULL;
}

static pan_t
pan_itop(int type)
{
	int i;
	
	for(i = 0; dlt_types[i].name; i++)
	{
		if(dlt_types[i].type == type)
			return dlt_types[i].pan;
	}
	return NULL;
}


id
pan_input(pan_req_t req, int dlt, const u_char *buf, size_t len)
{
	pan_t dlt_ptr;
	pbuf_t p_buf = {0};
	
	p_buf.dlt = dlt;
	p_buf.len = len;
	p_buf.req = req;
	p_buf.obj = nil;
	p_buf.data = buf;
	
	switch(req)
	{
		case PAN_SRC_STRING:
		case PAN_DST_STRING:
		case PAN_PROTO_STRING:
		case PAN_INFO_STRING:
			if(!(dlt_ptr = pan_itop(p_buf.dlt)))
				return PAN_UNKNOWN;
			
			(*dlt_ptr)(&p_buf);
			break;
			
		default:
			break;
	}
	
	return p_buf.obj;
}
