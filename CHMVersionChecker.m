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
// $Revision: 1.4 $
//

#import "CHMVersionChecker.h"
#import "MacPADSocket.h"

@interface CHMVersionChecker () <MacPADSocketNotifications>

@end

@implementation CHMVersionChecker

NSString *const AUTOMATIC_CHECK_PREF = @"VersionChecker:automaticCheck";
static NSString *const DAYS_BETWEEN_AUTOMATIC_CHECKS_PREF = @"VersionChecker:daysBetweenAutomaticChecks";
static NSString *const DAYS_BETWEEN_AUTOMATIC_NORMAL_CHECKS_PREF = @"VersionChecker:daysBetweenAutomaticNormalChecks";
static NSString *const DAYS_BETWEEN_AUTOMATIC_ALERT_CHECKS_PREF = @"VersionChecker:daysBetweenAutomaticAlertChecks";
static NSString *const LAST_CHECK_DATE_PREF = @"VersionChecker:lastCheckDate";
static NSString *const FIRST_TIME_PREF = @"VersionChecker:firstTime";

#pragma mark Lifecycle

+ (void)initialize
{
	[[NSUserDefaults standardUserDefaults]
		registerDefaults:
			@{ FIRST_TIME_PREF : @YES,
			   AUTOMATIC_CHECK_PREF : @YES,
			   DAYS_BETWEEN_AUTOMATIC_CHECKS_PREF : @0,
			   DAYS_BETWEEN_AUTOMATIC_NORMAL_CHECKS_PREF : @7,
			   DAYS_BETWEEN_AUTOMATIC_ALERT_CHECKS_PREF : @1,
			   LAST_CHECK_DATE_PREF : [NSDate distantPast],
			}];
}

- (id)init
{
	if (self = [super init]) {
		[NSBundle loadNibNamed:@"VersionChecker" owner:self];

		_isAutomaticCheck = FALSE;
		_macPAD = [[MacPADSocket alloc] init];
		[_macPAD setDelegate:self];
	}

	return self;
}

- (void)awakeFromNib
{
	// Update title of windows with application's name
	NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
	[_updateAvailableWindow setTitle:[NSString stringWithFormat:[_updateAvailableWindow title], appName]];
	[_upToDateWindow setTitle:[NSString stringWithFormat:[_upToDateWindow title], appName]];
	[_cannotCheckWindow setTitle:[NSString stringWithFormat:[_cannotCheckWindow title], appName]];

	NSCellStateValue preferenceState = [[NSUserDefaults standardUserDefaults] boolForKey:AUTOMATIC_CHECK_PREF] ? NSOnState : NSOffState;
	[_preferenceButton1 setState:preferenceState];
	[_preferenceButton2 setState:preferenceState];
	[_preferenceButton3 setState:preferenceState];
}

#pragma mark Activation

- (void)checkForNewVersion
{
	//NSLog(@"CHMVersionChecker :: checkForNewVersion");

	@synchronized(self)
	{
		_isAutomaticCheck = FALSE;
		[_macPAD performCheck];
	}
}

- (void)automaticallyCheckForNewVersion
{
	//NSLog(@"CHMVersionChecker :: automaticallyCheckForNewVersion");

	@synchronized(self)
	{
		if ([self shouldAutomaticallyCheckForNewVersion]) {
			_isAutomaticCheck = TRUE;
			[_macPAD performCheck];
		}
	}
}

#pragma mark Actions

- (IBAction)closeWindow:(id)sender
{
	if ([NSApp modalWindow]) {
		[[NSApp modalWindow] close];
		[NSApp abortModal];
	}
}

- (IBAction)update:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[_macPAD productPageURL]]];
	[self closeWindow:nil];
}

- (IBAction)changePreference:(id)sender
{
	NSCellStateValue state = [sender state];
	[_preferenceButton1 setState:state];
	[_preferenceButton2 setState:state];
	[_preferenceButton3 setState:state];
	[[NSUserDefaults standardUserDefaults] setBool:(state == NSOnState) forKey:AUTOMATIC_CHECK_PREF];
	[[NSNotificationCenter defaultCenter] postNotificationName:AUTOMATIC_CHECK_PREF object:sender];
}

#pragma mark NSWindow delegate

- (BOOL)windowShouldClose:(id)sender
{
	return YES;
}

#pragma mark MacPADSocket delegate

- (void)macPADErrorOccurred:(NSNotification *)notification
{
	//NSLog( @"Error while checking for new version: %@", [[notification userInfo] objectForKey:MacPADErrorMessage]);

	if ([self shouldNotifyLackOfNewVersion]) {
		[NSApp runModalForWindow:_cannotCheckWindow];
	}

	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:FIRST_TIME_PREF];
}

- (void)macPADCheckFinished:(NSNotification *)notification
{
	if ([[[notification userInfo] objectForKey:MacPADNewVersionAvailable] boolValue]) {
		// New version available
		[self updateNewVersionAvailability:YES];

		NSString *format = [_updateDescriptionTextField stringValue];

		NSString *releaseText = [[_macPAD releaseDate] descriptionWithCalendarFormat:@"%Y-%m-%d" timeZone:nil locale:nil];
		NSTimeInterval releaseAge = -[[_macPAD releaseDate] timeIntervalSinceNow] / 60.0 / 60.0 / 24.0;

		[_updateDescriptionTextField setStringValue:[NSString stringWithFormat:format,
																			   releaseText, [_macPAD newVersion], (int)releaseAge, [_macPAD currentVersion]]];

		[NSApp runModalForWindow:_updateAvailableWindow];
		[_updateDescriptionTextField setStringValue:format];
	} else if ([self shouldNotifyLackOfNewVersion]) {
		// Running version is up to date
		[self updateNewVersionAvailability:NO];
		[NSApp runModalForWindow:_upToDateWindow];
	}
}

#pragma mark Preferences

- (void)updateNewVersionAvailability:(BOOL)isNewVersionAvailable
{
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];

	[prefs setObject:[NSDate date] forKey:LAST_CHECK_DATE_PREF];

	if (isNewVersionAvailable) {
		[prefs setInteger:[prefs integerForKey:DAYS_BETWEEN_AUTOMATIC_ALERT_CHECKS_PREF]
				   forKey:DAYS_BETWEEN_AUTOMATIC_CHECKS_PREF];
	} else {
		[prefs setInteger:[prefs integerForKey:DAYS_BETWEEN_AUTOMATIC_NORMAL_CHECKS_PREF]
				   forKey:DAYS_BETWEEN_AUTOMATIC_CHECKS_PREF];
	}

	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:FIRST_TIME_PREF];
}

- (BOOL)shouldAutomaticallyCheckForNewVersion
{
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];

	if ([prefs boolForKey:AUTOMATIC_CHECK_PREF]) {
		NSInteger daysSinceLastCheck = -[[prefs objectForKey:LAST_CHECK_DATE_PREF] timeIntervalSinceNow] / (60 * 60 * 24);
		NSLog(@"CHMVersionChecker: %ld days since last time", (long)daysSinceLastCheck);

		return (daysSinceLastCheck >= [prefs integerForKey:DAYS_BETWEEN_AUTOMATIC_CHECKS_PREF]);
	}

	return NO;
}

- (BOOL)shouldNotifyLackOfNewVersion
{
	if (_isAutomaticCheck) {
		return [[NSUserDefaults standardUserDefaults] boolForKey:FIRST_TIME_PREF];
	}

	return YES;
}

@end
