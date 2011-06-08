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

#import "PCAPController.h"

#import <SecurityFoundation/SFAuthorization.h>
#import <sys/types.h>
#import <sys/stat.h>

#import "ConfigurationConstants.h"
#import "MACaptureDevice.h"
#import "MAPacket.h"
#import "MADate.h"


@implementation PCAPController

static PCAPController *sharedController = nil;

+ (id)sharedPCAPController
{
	@synchronized(self)
	{
		if(sharedController == nil)
			sharedController = [[[self class] alloc] init];
	}
	return sharedController;
}

+ (id)allocWithZone:(NSZone *)zone
{
	@synchronized(self)
	{
		if(sharedController == nil)
		{
			sharedController = [super allocWithZone:zone];
			return sharedController;
		}
	}
	return nil;
}

/* Make our singleton play nice. */
- (id)copyWithZone:(NSZone *)zone
{
	return self;
}

- (id)retain
{
	return self;
}

- (NSUInteger)retainCount
{
	return NSUIntegerMax;
}

- (void)release
{
}

- (id)autorelease
{
	return self;
}

- (id)init
{
	if(![super init])
		return nil;
	
	_auth = [[SFAuthorization authorization] retain];
	
	/* Create random key for our distributed object. */
	srandomdev();
	_rootProxyKey = [[NSString alloc] initWithFormat:@"%@<%02x%02x>",
					 MAPCAPControllerKey, random()%255, random()%255];
	
	_conn = [NSConnection new];
	[_conn setRootObject:self];
	if(![_conn registerName:_rootProxyKey])
	{
		NSLog(@"Oops! (%s)", __func__);
	}
	
	return self;
}

- (void)dealloc
{
	/* Close our file and delete it. */
	close(_pcapPipe);
	unlink(_pcapPipeName);
	
	[_pcapProxy stopRunLoop];
	[_pcapProxy release];
	[_conn registerName:nil];
	[_conn release];
	[_auth release];
	[super dealloc];
}

#pragma mark - Misc

- (void)shutdown
{
	if(_conn != nil)
	{
		if([_conn isValid])
			[_pcapProxy stopRunLoop];
		
		[_conn registerName:nil];
		[_conn release];
	}
	
	if(_pcapPipeName)
	{
		close(_pcapPipe);
		unlink(_pcapPipeName);
	}
	
	[_pcapProxy release];
}

- (BOOL)createPCAPHelper
{
	BOOL isAuth = [_auth obtainWithRights:NULL
								    flags:kAuthorizationFlagExtendRights
							  environment:NULL
						 authorizedRights:NULL
									error:NULL];
	if(!isAuth)
		return NO;
	
	if(_isConnected)
		return YES;
	
	/* Create a random FIFO file. */
	_pcapPipeName = tmpnam(NULL);
	
	if(mkfifo(_pcapPipeName, S_IRUSR|S_IWOTH) == -1)
		return NO;
	
	/*
	 * Open our pipe in non-blocking mode, then switch back to
	 * blocking while reading from the pipe.
	 */
	_pcapPipe = open(_pcapPipeName, O_RDONLY|O_NONBLOCK);
	int curFlags = fcntl(_pcapPipe, F_GETFL);
	fcntl(_pcapPipe, F_SETFL, curFlags & ~O_NONBLOCK);
	
	[self setupDispatchQueue];
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		
		/* Arguments to send to the helper. */
		char *argv[] = {
			(char *)[_rootProxyKey UTF8String],
			_pcapPipeName,
			NULL
		};
		AuthorizationExecuteWithPrivileges([_auth authorizationRef], MAHelperPath,
											kAuthorizationFlagDefaults,
											argv, NULL);
	});
	
	return NO;
}
 
#pragma mark - Distributed Object methods

- (oneway void)connectPCAPHelperWithKey:(NSString *)key
{
	if(_pcapProxy)
		return;
	
	_pcapProxy = [[NSConnection
				   rootProxyForConnectionWithRegisteredName:key host:nil] retain];
	[_pcapProxy setProtocolForProxy:@protocol(MAPCAPHelperProtocol)];
	_isConnected = YES;
	
	/*
	 * Post notification to alert our AppController that we can preform
	 * administrative tasks via mahelper.
	 */
	[[NSNotificationCenter defaultCenter] postNotificationName:MAPCAPReadyNotificationKey
														object:self];
}

#pragma mark - Grand Central Dispatch

- (BOOL)setupDispatchQueue
{
	if(!(_dispatchQueue = dispatch_queue_create(MADispatchFIFOSourceQueue, NULL)))
		return NO;
	
	_dispatchSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ,
											 _pcapPipe,
											 0,
											 _dispatchQueue);
	if(!_dispatchSource)
		return NO;
	
	/* Process packets as they arrive and pass them off to our delegate. */
	dispatch_source_set_event_handler(_dispatchSource, ^{
		char *data;
		NSUInteger len;
		
		readall(_pcapPipe, &len, sizeof(len));
		if(!(data = malloc(sizeof(*data)*len)))
			return;
		
		readall(_pcapPipe, data, sizeof(*data)*len);
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
			char *packetData;
			char *deviceName;
			struct pcap_pkthdr *hdr;
			NSUInteger packetId;
			NSString *devName;
			MAPacket *newPacket;
			
			packetId = *(NSUInteger *)data;
			hdr = (struct pcap_pkthdr *)(data+sizeof(packetId));
			packetData = (char *)hdr+sizeof(*hdr);
			deviceName = packetData+hdr->caplen;
			devName = [[NSString alloc] initWithBytes:deviceName
											   length:len-(deviceName-data)
											 encoding:NSUTF8StringEncoding];
			
			MACaptureDevice *dev = [self.deviceList objectForKey:devName];
			newPacket = [[MAPacket alloc] initWithData:packetData
											withHeader:hdr
												withId:packetId
											fromDevice:dev];
			dispatch_async(dispatch_get_main_queue(), ^{
				[self processPacket:newPacket];
				[newPacket release];
			});
			
			[devName release];
			free(data);
		});
	});
	dispatch_resume(_dispatchSource);
	
	return YES;
}

- (void)closeDispatchQueue
{
	/* Stop our dispatch source and queue. */
	dispatch_source_cancel(_dispatchSource);
	dispatch_release(_dispatchSource);
	dispatch_release(_dispatchQueue);
}

#pragma mark - Process Packets

- (oneway void)processPacket:(MAPacket *)packet
{
	if(![_delegate respondsToSelector:@selector(addPacket:)])
		return;
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[_delegate addPacket:packet];
	});
}

#pragma mark - Accessors

- (NSDictionary *)deviceList
{
	if(_deviceList == nil && self.isConnected)
		_deviceList = [[_pcapProxy deviceList] retain];
	
	return _deviceList;
}

@synthesize delegate			= _delegate;
@synthesize isConnected			= _isConnected;

@end
