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

#import "MAPacket.h"

#import "MADate.h"
#import "pan.h"

@implementation MAPacket

#pragma mark -
#pragma mark Init/Dealloc

- (id)init
{
	return nil;
}

- (BOOL)test
{
	return YES;
}

- (id)initWithData:(const void *)bytes
		withHeader:(const struct pcap_pkthdr *)header
			withId:(NSUInteger)identification
		fromDevice:(id<MACaptureProtocol>)device
{
	if(![super init])
		return nil;
	
	_id = identification;
	_deviceUUID = [device.uuid retain];
	_datalink = [device dataLink];
	
	memcpy(&_header, header, sizeof(_header));
	
	if(!(_bytes = malloc(sizeof(*_bytes)*_header.caplen)))
	{
		/* XXX Error handling */
	}
	
	memcpy(_bytes, bytes, sizeof(*_bytes)*_header.caplen);
	
	return self;
}

- (void)dealloc
{
	free(_bytes);
	[_deviceUUID release];
	[super dealloc];
}

#pragma mark -
#pragma mark Basic packet processing

- (NSString *)source
{
	return pan_input(PAN_SRC_STRING, _datalink, self.bytes, self.length);
}

- (NSString *)destination
{
	return pan_input(PAN_DST_STRING, _datalink, self.bytes, self.length);
}

- (NSString *)protocol
{
	return pan_input(PAN_PROTO_STRING, _datalink, self.bytes, self.length);
}

- (NSString *)description
{
	return pan_input(PAN_INFO_STRING, _datalink, self.bytes, self.length);
}

#pragma mark -
#pragma mark Accessors

- (const struct pcap_pkthdr *)header
{
	return &_header;
}

- (NSData *)data
{
	return [NSData dataWithBytesNoCopy:(voidPtr)self.bytes
								length:self.header->caplen
						  freeWhenDone:NO];
}

- (NSInteger)length
{
	return self.header->caplen;
}

- (NSDate *)time
{
	return [NSDate dateWithTimeVal:self.header->ts];
}

@synthesize bytes			= _bytes;
@synthesize number			= _id;
@synthesize deviceUUID		= _deviceUUID;

@end
