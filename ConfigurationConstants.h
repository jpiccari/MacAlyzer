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


#define MAWindowTitle				@"MacAlyzer"

#define MADispatchFIFOSourceQueue	"com.joshuapiccari.MacAlyzer.FIFO"

#define MAPCAPControllerKey			@"com.joshuapiccari.MacAlyzer.IPC.PCAPController"
#define MAPCAPHelperKey				@"com.joshuapiccari.MacAlyzer.IPC.PCAPHelper"

#define MAHelperPath				[[[NSBundle mainBundle]				\
										pathForAuxiliaryExecutable:@"mahelper"] UTF8String]

#define MAToolbarStartKey			@"com.joshuapiccari.MacAlyzer.startCapture"

#define MAPCAPReadyNotificationKey	@"com.joshuapiccari.MacAlyzer.PCAPReadyNotification"
#define MARecentCapNotificationKey	@"com.joshuapiccari.MacAlyzer.RecentCapNotification"
#define MANewPacketNotificationKey	@"com.joshuapiccari.MacAlyzer.NewPacketCountNotification"

#define MANewPacketCountKey			@"countNewPackets"

#define MAImageInterfaceKey			@"interfaceImage"
#define MAImageRecentSaveFileKey	@"recentSavefileImage"
#define MAImageToolbarStartKey		@"toolbarStartImage"
#define MAImageToolbarPauseKey		@"toolbarPauseImage"

#define MAInterfacesKey				@"DEVICES"
#define MARecentCapturesKey			@"RECENT CAPTURES"

#define MAToolbarCaptureStart		@"Start"
#define MAToolbarCapturePause		@"Pause"

#define MASidebarMinWidth			155
#define MASidebarMaxWidth			350

#define	MAPacketViewMinWidth		100

#define MACaptureUpdateInterval		1/2
#define MASaveFileUpdateInterval	1/32

#define MACaptureWindowNibName		@"MACapture"

#define MADocumentTypePCAPDevice	@"PCAP Device"
#define MADocumentTypePCAPSavefile	@"PCAP Savefile"

#define MAShowSidebarText			@"Show Sidebar"
#define MAHideSidebarText			@"Hide Sidebar"
#define MAShowPacketDumpText		@"Show Packet Dump"
#define MAHidePacketDumpText		@"Hide Packet Dump"

#define MASplitViewAnimateDuration	0.25


#define createPacketSource(key)											\
	{																	\
		NSDictionary *cps_dict;											\
		NSMutableSet *cps_set = [[NSMutableSet alloc] init];			\
		NSMutableArray *cps_array = [[NSMutableArray alloc] init];		\
		cps_dict = [[NSDictionary alloc] initWithObjectsAndKeys:		\
				cps_set, MAPacketSourceBuffer,							\
				cps_array, MAPacketSourceList,							\
				nil];													\
																		\
		[packetSources setObject:cps_dict forKey:key];					\
		[cps_set release];												\
		[cps_array release];											\
		[cps_dict release];												\
	}

