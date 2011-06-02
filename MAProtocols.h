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

#import <pcap/pcap.h>

@class MACaptureDevice;
@class MAPacket;


/* Capture device/file. */
typedef enum
{
	PCAP_SAVEFILE,
	PCAP_DEVICE
} cap_device_t;

@protocol MACaptureProtocol <NSObject>

@property (readonly) cap_device_t deviceType;
@property (readonly) NSString *deviceName;
@property (readonly) NSString *uuid;
@property (readonly) int dataLink;

@end

/* Protocol used by packet processing classes. */
@protocol MAPacketProcessor <NSObject>

@property (readonly) NSInteger number;
@property (readonly) NSString *deviceUUID;

@property (readonly) NSDate *time;
@property (readonly) NSInteger length;

@property (readonly) NSString *source;
@property (readonly) NSString *destination;

@property (readonly) NSString *protocol;
@property (readonly) NSString *description;

@end


/* Protocol used for PCAP Controller<->Helper relations. */
@protocol PCAPControllerProtocol

- (oneway void)connectPCAPHelperWithKey:(NSString *)key;
- (oneway void)processPacket:(MAPacket *)packet;

@end


/* PCAPController delegate protocol. */
@protocol PCAPControllerDelegate
@optional
- (void)addPacket:(MAPacket *)packet;
@end



/* Protocol used for PCAP Controller<->Helper relations. */
@protocol MAPCAPHelperProtocol

- (void)startRunLoop;
- (void)stopRunLoop;

- (NSDictionary *)deviceList;

@end


/* Protocol used for MACaptureDevice delegates. */
@protocol MACaptureDeviceDelegate

- (void)processPacket:(NSData *)data;

@end
