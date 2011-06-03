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


@interface MAPacket : NSObject <MAPacketProcessor> {
@private
	struct pcap_pkthdr _header;
	u_char *_bytes;
	NSInteger _id;
	NSString *_deviceUUID;
	int _datalink;
}

- (id)initWithData:(const void *)bytes
		withHeader:(const struct pcap_pkthdr *)header
			withId:(NSUInteger)identification
		fromDevice:(id<MACaptureProtocol>)device;

- (id)initWithData:(const void *)bytes
		withHeader:(const struct pcap_pkthdr *)header
			withId:(NSUInteger)identification
		  withUUID:(NSString *)uuid
	  withDataLink:(int)dataLink;

@property (readonly) const struct pcap_pkthdr *header;
@property (readonly) const u_char *bytes;
@property (readonly) NSData *data;
@property (readonly) NSInteger length;
@property (readonly) NSInteger number;
@property (readonly) NSDate *time;
@property (readonly) NSString *deviceUUID;

@end
