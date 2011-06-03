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

#import <Foundation/Foundation.h>
#import <pcap/pcap.h>

#import "MAProtocols.h"


@interface MACaptureDevice : NSObject <MACaptureProtocol> {
@private
	NSUInteger _nextPacketId;
	pcap_t *_captureSession;
	char _captureErrorBuffer[PCAP_ERRBUF_SIZE];
	int _captureDatalinkType;
	
	NSString *_deviceName;
	NSString *_deviceDescription;
	pcap_addr_t *_deviceAddress;
	bpf_u_int32 _deviceFlags;
	NSString *_uuid;
	
	BOOL _promiscMode;
	BOOL _rfmonMode;
	int _dataLink;
	int _maxPacketSize;
	int _readDelay;
	
	BOOL _isCapturing;
	
	id _delegate;
}

- (id)initWithName:(char *)ifaceName
	   description:(char *)desc
		   address:(pcap_addr_t *)addr
			 flags:(bpf_u_int32)flags;


- (BOOL)startCapture;
- (void)stopCapture;
- (BOOL)setFilter:(NSString *)expr;

- (BOOL)isLoopBack;
- (void)cloneAddress:(pcap_addr_t *)addr;

- (void)sendPacket:(const u_char *)data
		withHeader:(const struct pcap_pkthdr *)hdr;

@property (readonly) NSURL *deviceURL;

@property (readonly) pcap_t *captureSession;
@property (readonly) NSString *captureErrorBuffer;
@property (readonly) int captureDatalinkType;

@property (readonly) NSString *deviceName;
@property (readonly) NSString *deviceDescription;
@property (readonly) pcap_addr_t *deviceAddress;
@property (readonly) bpf_u_int32 deviceFlags;
@property (readonly) BOOL isCapturing;

@property (readwrite) BOOL promiscuousMode;
@property (readwrite) BOOL monitorMode;
@property (readonly) int dataLink;
@property (readwrite) int maxPacketSize;
@property (readwrite) int readDelay;

@property (readwrite, assign) id delegate;

@end
