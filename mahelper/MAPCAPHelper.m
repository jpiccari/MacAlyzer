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

#import "MAPCAPHelper.h"

#import <CoreFoundation/CFRunLoop.h>
#import <errno.h>

#import "ConfigurationConstants.h"
#import "MACaptureDevice.h"


@implementation MAPCAPHelper

- (id)init
{
	if(![super init])
		return nil;
	
	_captureDevices = [[NSMutableDictionary alloc] init];
	srandomdev();
	_pcapHelperKey = [[NSString alloc] initWithFormat:@"%@<%02x%02x>",
					  MAPCAPHelperKey, random()%255, random()%255];
	
	return self;
}

- (void)dealloc
{
	if(_pipeName)
		close(_pipeDescriptor);
	[_pcapHelperKey release];
	[_pcapControllerKey release];
	[_pcapController release];
	[_captureDevices release];
	[super dealloc];
}

#pragma mark -
#pragma mark Run Loop

- (void)startRunLoop
{
	/* Initialize our device list. */
	[self deviceList];
	
	/* Open our pipe for writing. */
	_pipeDescriptor = open(self.pipeName, O_WRONLY);
	
	/* Notify the main app that we are ready. */
	_pcapController = [NSConnection
					  rootProxyForConnectionWithRegisteredName:self.controllerKey
														  host:nil];
	[_pcapController setProtocolForProxy:@protocol(PCAPControllerProtocol)];
	[_pcapController connectPCAPHelperWithKey:self.pcapHelperKey];
	
	/* Start the run loop. */
	if(_pcapController)
	{
		/* Register for NSConnectionDidDieNotification in case of errror. */
		[[NSNotificationCenter defaultCenter]
		 addObserver:self
			selector:@selector(connectionDied:)
				name:NSConnectionDidDieNotification
			  object:[_pcapController connectionForProxy]];
		
		CFRunLoopRun();
	}
}

- (void)stopRunLoop
{
	CFRunLoopStop(CFRunLoopGetCurrent());
}

#pragma mark -
#pragma mark Misc

- (void)connectionDied:(NSNotification *)notification
{
	/* We should unlink our FIFO since the main program probably crashed. */
	close(_pipeDescriptor);
	unlink(self.pipeName);
	self.pipeName = NULL;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self stopRunLoop];
}

- (NSDictionary *)deviceList
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	pcap_if_t *alldevs;
	pcap_if_t *curdev;
	char errbuf[PCAP_ERRBUF_SIZE];
	
	if(pcap_findalldevs(&alldevs, errbuf) == -1)
		return nil;
	
	for(curdev = alldevs; curdev; curdev = curdev->next)
	{
		if([_captureDevices objectForKey:
			[NSString stringWithUTF8String:curdev->name]])
			continue;
		
		MACaptureDevice *dev =
		[[MACaptureDevice alloc] initWithName:curdev->name
								  description:curdev->description
									  address:curdev->addresses
										flags:curdev->flags];
		
		[dev setDelegate:self];
		[_captureDevices setObject:dev forKey:[dev deviceName]];
		[dev release];
	}
	
	pcap_freealldevs(alldevs);
	[pool drain];
	
	return _captureDevices;
}

- (void)processPacket:(NSUInteger)packetId
			 withData:(const u_char *)data
		   withHeader:(const struct pcap_pkthdr *)hdr
			forDevice:(MACaptureDevice *)device
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSMutableData *theData = [[NSMutableData alloc] init];
	NSString *deviceName = [device deviceName];
	const char *dev_name = [deviceName UTF8String];
	NSUInteger len = [deviceName length];
	NSUInteger totalLen = sizeof(packetId)+sizeof(*hdr)+hdr->caplen+len;
	
	[theData appendBytes:&totalLen length:sizeof(totalLen)];
	[theData appendBytes:&packetId length:sizeof(packetId)];
	[theData appendBytes:hdr length:sizeof(*hdr)];
	[theData appendBytes:data length:hdr->caplen];
	[theData appendBytes:dev_name length:len];
	
	write(_pipeDescriptor, [theData bytes], [theData length]);
	[theData release];
	[pool drain];
}

#pragma mark -
#pragma mark Accessors

@synthesize captureDevices	= _captureDevices;
@synthesize controllerKey	= _pcapControllerKey;
@synthesize pipeName		= _pipeName;
@synthesize pcapHelperKey	= _pcapHelperKey;

@end
