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

#import "MACapture.h"

#import <pcap/pcap.h>

#import "ConfigurationConstants.h"

#import "MADocumentController.h"
#import "MAWindowController.h"
#import "PCAPController.h"
#import "MACaptureDevice.h"
#import "MAPacket.h"
#import "MAString.h"


/*
 * Bounce our callback to an Objective-C method.
 */
void
ma_local_pcap_callback(u_char *obj, const struct pcap_pkthdr *hdr,
					   const u_char *data)
{
	[(id)obj newPacket:data withHeader:hdr];
}

@implementation MACapture

- (id)init
{
	if(!(self = [super init]))
		return nil;
	
	_docController = [MADocumentController sharedDocumentController];
	_buffer = [NSMutableSet new];
	_packets = [NSMutableArray new];
	
	return self;
}

- (void)dealloc
{
	[_buffer release];
	[_packets release];
	[_deviceUUID release];
	[super dealloc];
}

#pragma mark - NSDocument Override methods

- (void)makeWindowControllers
{
	MAWindowController *winController;
	
	/* Only create a new window, if we don't have one yet. */
	if([NSApp mainWindow])
	{
		winController = [[[NSApp mainWindow] windowController] retain];
		
		/* Remove the old document. */
		MACapture *oldDocument = [winController document];
		[oldDocument removeWindowController:winController];
		if([oldDocument deviceType] != PCAP_DEVICE &&
		   [[oldDocument windowControllers] count] == 0)
			[oldDocument close];
	}
	else
		winController = [MAWindowController new];
	
	[self addWindowController:winController];
	[winController updatePacketStats];
	[winController release];
}

- (void)showWindows
{
	/* Only show the most recent window. */
	[[[self windowControllers] lastObject] showWindow:self];
}

- (BOOL)writeToURL:(NSURL *)absoluteURL
			ofType:(NSString *)typeName
			 error:(NSError **)outError
{
	if([typeName isEqualToString:MADocumentTypePCAPSavefile])
	{
		BOOL freeSession = NO;
		pcap_t *session = NULL;
		pcap_dumper_t *dumper;
		
		if([[[self fileURL] scheme] isEqualToString:@"device"])
		{
			/* XXX Uhh, not sure what to do yet. */
			MACaptureDevice *device = [[[PCAPController sharedPCAPController]
										deviceList] objectForKey:
									   [[self fileURL] lastPathComponent]];
			
			if(device == nil)
				return NO;
			
			if(!(session = pcap_open_dead([device dataLink],
										  [device maxPacketSize])))
			{
				/* XXX Error handling. */
				return NO;
			}
			freeSession = YES;
		}
		
		else if([[[self fileURL] scheme] isEqualToString:@"file"] && _session)
		{
			session = _session;
		}
		
		if(!session)
			return NO;
		
		if(!(dumper = pcap_dump_open(session,
									 [[absoluteURL path] UTF8String])))
		{
			/* XXX err checking */
			return NO;
		}
		
		for(MAPacket *packet in _packets)
			pcap_dump((u_char *)dumper, [packet header], [packet bytes]);
		
		pcap_dump_close(dumper);
		
		if(freeSession)
			pcap_close(session);
		
		return YES;
	}
	
	return NO;
}

- (BOOL)readFromURL:(NSURL *)absoluteURL
			 ofType:(NSString *)typeName
			  error:(NSError **)outError
{
	if([typeName isEqualToString:MADocumentTypePCAPDevice])
	{
		/* Don't need to do much since the device takes care of it. */
		_deviceType = PCAP_DEVICE;
		_deviceUUID = [[[absoluteURL absoluteString] md5] copy];
		[[[MADocumentController sharedDocumentController]
		  deviceDocuments] setObject:self forKey:_deviceUUID];
		return YES;
	}
	
	else if([typeName isEqualToString:MADocumentTypePCAPSavefile])
	{
		_deviceType = PCAP_SAVEFILE;
		char errbuf[PCAP_ERRBUF_SIZE];
		
		if(!(_session = pcap_open_offline([[absoluteURL path] UTF8String], errbuf)))
		{
			/* XXX Needs detailed error checking. */
			return NO;
		}
		
		_packetId = 1;
		_dataLink = pcap_datalink(_session);
		_deviceUUID = [[[absoluteURL absoluteString] md5] copy];
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			pcap_loop(_session, -1, ma_local_pcap_callback, (voidPtr)self);
		});
		
		return YES;
	}
	
	return NO;
}

#pragma mark - KVC for buffer (_buffer)

- (NSUInteger)countOfBuffer
{
	@synchronized(_buffer)
	{
		return [_buffer count];
	}
}

- (NSEnumerator *)enumeratorOfBuffer
{
	return [_buffer objectEnumerator];
}

- (MAPacket *)memberOfBuffer:(MAPacket *)object
{
	@synchronized(_buffer)
	{
		return [_buffer member:object];
	}
}

- (void)addBufferObject:(MAPacket *)object
{
	@synchronized(_buffer)
	{
		[_buffer addObject:object];
	}
	_packetsCaptured++;
	_bytesCaptured += ((struct pcap_pkthdr *)[object header])->caplen;
}

- (void)removeBuffer:(NSSet *)objects
{
	@synchronized(_buffer)
	{
		[_buffer minusSet:objects];
	}
}

- (void)intersectBuffer:(NSSet *)objects
{
	@synchronized(_buffer)
	{
		[_buffer intersectSet:objects];
	}
}

#pragma mark - KVC for packets (_packets)

- (NSUInteger)countOfPackets
{
	return [_packets count];
}

- (id)objectInPacketsAtIndex:(NSUInteger)index
{
	return [_packets objectAtIndex:index];
}

- (void)insertObject:(MAPacket *)object inPacketsAtIndex:(NSUInteger)index
{
	[_packets insertObject:object atIndex:index];
}

- (void)insertPackets:(NSArray *)packets atIndexes:(NSIndexSet *)indexes
{
	[_packets insertObjects:packets atIndexes:indexes];
}

- (void)removeObjectFromPacketsAtIndex:(NSUInteger)index
{
	[_packets removeObjectAtIndex:index];
}

#pragma mark - Misc

- (void)newPacket:(const u_char *)data
	   withHeader:(const struct pcap_pkthdr *)header
{
	MAPacket *packet = [[MAPacket alloc] initWithData:data
										   withHeader:header
											   withId:_packetId++
											 withUUID:_deviceUUID
										 withDataLink:_dataLink];
	
	[self addBufferObject:packet];
	[packet release];
	
	/* If this is a savefile, update our _fileTimer. */
	if(_deviceType == PCAP_SAVEFILE)
	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[_docController requestFileTimerUpdate:self];
		});
	}
}

- (NSInteger)updatePacketsWithSortDescriptors:(NSArray *)descriptors
{
	NSUInteger bufferCount;
	NSArray *newPackets;
	
	@synchronized(_buffer)
	{
		bufferCount = [_buffer count];
		if(bufferCount == 0)
			return 0;
		
		newPackets = [_buffer sortedArrayUsingDescriptors:descriptors];
		[_buffer removeAllObjects];
		
	}
	
	/* Using manual KVO notifications since this will be updating fast. */
	[self willChangeValueForKey:@"packets"];
	[_packets addObjectsFromArray:newPackets];
	[self didChangeValueForKey:@"packets"];
	
	for(MAWindowController *winController in [self windowControllers])
		[winController updatePacketStats];
	
	/* Notify others that we have new packets. */
	NSDictionary *userInfo =
	[NSDictionary dictionaryWithObject:[NSNumber
										numberWithUnsignedInteger:bufferCount]
								forKey:MANewPacketCountKey];
	[[NSNotificationCenter defaultCenter]
	  postNotificationName:MANewPacketNotificationKey
					object:self
				  userInfo:userInfo];
	
	return bufferCount;
}

#pragma mark - Accessors

@synthesize deviceType				= _deviceType;
@synthesize deviceUUID				= _deviceUUID;
@synthesize bytesCaptured			= _bytesCaptured;
@synthesize packetsCaptured			= _packetsCaptured;
@synthesize buffer					= _buffer;
@synthesize packets					= _packets;
@synthesize dataLinkLayer			= _dataLinkLayer;
@synthesize session					= _session;

@end
