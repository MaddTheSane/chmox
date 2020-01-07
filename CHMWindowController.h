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
// $Revision: 1.5 $
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebUIDelegate.h>
#import <WebKit/WebPolicyDelegate.h>
#import <WebKit/WebView.h>
#import "CHMDocument.h"

NS_ASSUME_NONNULL_BEGIN

@interface CHMWindowController : NSWindowController <NSToolbarDelegate, NSOutlineViewDelegate, WebUIDelegate, WebPolicyDelegate, NSTableViewDataSource, NSMenuItemValidation>

@property (weak) IBOutlet WebView *contentsView;
@property (weak) IBOutlet NSDrawer *drawer;
@property (weak) IBOutlet NSOutlineView *tocView;
@property (weak) IBOutlet NSTableView *favoritesView;
@property (weak) IBOutlet NSTabView *drawerView;
@property (weak) IBOutlet NSSegmentedControl *historyToolbarItemView;
@property (weak) IBOutlet NSTableView *searchResultsView;
@property (weak) IBOutlet NSSearchField *searchField;

- (void)setupToolbar;
- (void)updateToolTipRects;

- (IBAction)toggleDrawer:(id _Nullable)sender;
- (IBAction)changeTopicWithSelectedRow:(id _Nullable)sender;
- (IBAction)changeTopicToPreviousInHistory:(id _Nullable)sender;
- (IBAction)changeTopicToNextInHistory:(id _Nullable)sender;
- (IBAction)makeTextSmaller:(id _Nullable)sender;
- (IBAction)makeTextBigger:(id _Nullable)sender;
- (IBAction)search:(id _Nullable)sender;
- (IBAction)searchResultSelected:(id _Nullable)sender;
- (IBAction)addBookmark:(id _Nullable)sender;
- (IBAction)removeBookmark:(id _Nullable)sender;
- (IBAction)loadBookmark:(id _Nullable)sender;

//- (NSArray<NSToolbarItemIdentifier> *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar;
//- (NSArray<NSToolbarItemIdentifier> *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar;
//- (nullable NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSToolbarItemIdentifier)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag;

@end

NS_ASSUME_NONNULL_END
