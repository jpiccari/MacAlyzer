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

#import "MACaptureDevice.h"

#import <arpa/inet.h>

#import "MADate.h"
#import "MAProtocols.h"
#import "MAPCAPHelper.h"
#import "MAString.h"


/*
 * Bounce our callback to an Objective-C method.
 */
void
ma_callback(u_char *obj, const struct pcap_pkthdr *hdr, const u_char *data)
{
	[(id)obj sendPacket:data withHeader:hdr];
}

@implementation MACaptureDevice

- (id)initWithName:(char *)ifaceName
	   description:(char *)desc
		   address:(pcap_addr_t *)addr
			 flags:(bpf_u_int32)theFlags
{
	if(![super init])
		return nil;
	
	_nextPacketId = 1;
	
	if(ifaceName)
		_deviceName = [NSString stringWithUTF8String:ifaceName];
	else
		_deviceName = @"<Unknown>";
	
	_deviceFlags = theFlags;
	
	if(desc)
		_deviceDescription = [NSString stringWithUTF8String:desc];
	else
		_deviceDescription = nil;
	
	/* Copy the addresses struct(s) */
	[self cloneAddress:addr];
	
	/* Generate UUID for device. */
	NSString *tempUUID = [NSString stringWithFormat:@"device://%@", _deviceName];
	_uuid = [[tempUUID md5] copy];
	
	return self;
}

- (void)dealloc
{
	[self stopCapture];
	[_uuid release];
	[_deviceName release];
	[_deviceDescription release];
	[super dealloc];
}

#pragma mark - PCAP methods

- (BOOL)startCapture
{
	if(_isCapturing)
		return YES;
	
	_isCapturing = YES;
	_captureSession = pcap_create([self.deviceName UTF8String],
								  _captureErrorBuffer);
	if(!_captureSession)
	{
		NSLog(@"%s(): %s", __func__, pcap_geterr(_captureSession));
		pcap_close(_captureSession);
		_isCapturing = NO;
		return NO;
	}
	
	/* Set Promiscious and monitor modes. */
	pcap_set_promisc(_captureSession, (self.promiscuousMode ? 1 : 0));
	pcap_set_rfmon(_captureSession, (self.monitorMode ? 1 : 0));
	
	/* Set snapshot length and read delay. */
	pcap_set_snaplen(_captureSession, self.maxPacketSize);
	pcap_set_timeout(_captureSession, self.readDelay);
	
	/* Cache popular variables. */
	_dataLink = pcap_datalink(_captureSession);
	
	/* Activate our capture device. */
	pcap_activate(_captureSession);
	_dataLink = pcap_datalink(_captureSession);
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
		pcap_loop(_captureSession, -1, ma_callback, (voidPtr)self);
	});
	
	return YES;
}

- (void)stopCapture
{
	if(!_isCapturing)
		return;
	else
		_isCapturing = NO;
	
	if(!_captureSession)
		return;

	pcap_breakloop(_captureSession);
	pcap_close(_captureSession);
	_captureSession = NULL;
}

- (BOOL)setFilter:(NSString *)expr
{
	return NO;
}

#pragma mark - Send packets

- (void)sendPacket:(const u_char *)data
		withHeader:(const struct pcap_pkthdr *)hdr
{
	if(![_delegate respondsToSelector:
		 @selector(processPacket:withData:withHeader:forDevice:)])
		return;
	
	[_delegate processPacket:_nextPacketId++ withData:data
				  withHeader:hdr forDevice:self];
}

#pragma mark - Misc

- (void)cloneAddress:(pcap_addr_t *)addr
{
	pcap_addr_t *cur_addr;
	pcap_addr_t *temp_addr = NULL;
	
	for(cur_addr = addr; cur_addr; cur_addr = cur_addr->next)
	{
		pcap_addr_t *new;
		
		if(!(new = calloc(sizeof(*new), 1)) ||
		   !(new->addr = malloc(sizeof(*new->addr))))
		{
			NSLog(@"%s: Ran out of memory?", __func__);
			return;
		}
		memcpy(new->addr, cur_addr->addr, sizeof(*new->addr));
		
		if(cur_addr->netmask)
		{
			if(!(new->netmask = malloc(sizeof(*new->netmask))))
			{
				NSLog(@"%s: Ran out of memory?", __func__);
				return;
			}
			memcpy(new->netmask, cur_addr->netmask, sizeof(*new->netmask));
		}
		
		if(cur_addr->broadaddr)
		{
			if(!(new->broadaddr = malloc(sizeof(*new->broadaddr))))
			{
				NSLog(@"%s: Ran out of memory?", __func__);
				return;
			}
			memcpy(new->broadaddr, cur_addr->broadaddr, sizeof(*new->broadaddr));
		}
		
		if(cur_addr->dstaddr)
		{
			if(!(new->dstaddr = malloc(sizeof(*new->dstaddr))))
			{
				NSLog(@"%s: Ran out of memory?", __func__);
				return;
			}
			memcpy(new->dstaddr, cur_addr->dstaddr, sizeof(*new->dstaddr));
		}
		
		new->next = NULL;
		if(!temp_addr)
			_deviceAddress = new;
		else
			temp_addr->next = new;
		
		temp_addr = new;
	}
}

- (BOOL)isLoopBack
{
	return ((_deviceFlags & PCAP_IF_LOOPBACK) > 0);
}

- (NSString *)description
{
	if(_deviceName && _deviceDescription)
		return [NSString stringWithFormat:@"%@ (%@)",
				_deviceName, _deviceDescription];
	else if(_deviceName)
		return _deviceName;
	
	return @"Unnamed device";
}

#pragma mark - Accessors

- (NSString *)captureErrorBuffer
{
	return [NSString stringWithUTF8String:_captureErrorBuffer];
}

- (void)setPromiscuousMode:(BOOL)mode
{
	if(!_isCapturing)
		_promiscMode = mode;
}

- (BOOL)promiscuousMode
{
	return _promiscMode;
}

- (void)setMonitorMode:(BOOL)mode
{
	if(!_isCapturing)
		_rfmonMode = mode;
}

- (BOOL)monitorMode
{
	return _rfmonMode;
}

- (void)setMaxPacketSize:(int)size
{
	if(!_isCapturing)
		_maxPacketSize = size;
}

- (int)maxPacketSize
{
	return _maxPacketSize;
}

- (void)setReadDelay:(int)delay
{
	_readDelay = delay;
}

- (int)readDelay
{
	return _readDelay;
}

- (cap_device_t)deviceType
{
	return PCAP_DEVICE;
}

@synthesize captureSession		= _captureSession;
@synthesize captureDatalinkType	= _captureDatalinkType;

@synthesize deviceAddress		= _deviceAddress;
@synthesize deviceDescription	= _deviceDescription;
@synthesize deviceFlags			= _deviceFlags;
@synthesize deviceName			= _deviceName;
@synthesize uuid				= _uuid;

@synthesize isCapturing			= _isCapturing;
@synthesize dataLink			= _dataLink;

@synthesize delegate			= _delegate;

@end
