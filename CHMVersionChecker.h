//
// Chmox a CHM file viewer for Mac OS X
// Copyright (c) 2004 Stéphane Boisson.
//
// Chmox is free software; you can redistribute it and/or modify it
// under the terms of the GNU Lesser General Public License as published
// by the Free Software Foundation; either version 2.1 of the License, or
// (at your option) any later version.
//
// Chmox is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with Foobar; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//
// $Revision: 1.3 $
//

#import <AppKit/AppKit.h>

extern NSString *const AUTOMATIC_CHECK_PREF; // Key for user defaults.

@class MacPADSocket;

@interface CHMVersionChecker : NSWindowController {
	MacPADSocket *_macPAD;
	bool _isAutomaticCheck;
}
@property (weak) IBOutlet NSPanel *updateAvailableWindow;
@property (weak) IBOutlet NSPanel *upToDateWindow;
@property (weak) IBOutlet NSPanel *cannotCheckWindow;
@property (weak) IBOutlet NSButton *preferenceButton1;
@property (weak) IBOutlet NSButton *preferenceButton2;
@property (weak) IBOutlet NSButton *preferenceButton3;

@property (weak) IBOutlet NSTextField *updateDescriptionTextField;

- (void)checkForNewVersion;
- (void)automaticallyCheckForNewVersion;

- (IBAction)closeWindow:(id)sender;
- (IBAction)update:(id)sender;
- (IBAction)changePreference:(id)sender;

- (BOOL)shouldAutomaticallyCheckForNewVersion;
- (BOOL)shouldNotifyLackOfNewVersion;
- (void)updateNewVersionAvailability:(BOOL)isNewVersionAvailable;

@end
