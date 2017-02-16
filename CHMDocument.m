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
// $Revision: 1.6 $
//

#import "CHMDocument.h"
#import "CHMTopic.h"
#import "CHMWindowController.h"
#import "CHMContainer.h"
#import "Chmox-Swift.h"
#import "CHMURLProtocol.h"

@class NSFileManager;

@implementation CHMDocument {
    NSMutableOrderedSet<NSString*> *__bookKeys;
    NSMutableOrderedSet<NSString*> *__searchKeys;
}

#pragma mark NSObject
- (id) init
{
    if (self = [super init]) {
        _container = nil;
        KEY_savedBookmarks = @"Chmox:savedBookmarks";
        __bookKeys = [[NSMutableOrderedSet alloc] init];
    }
    return self;
}


- (void) dealloc
{
    if (_container) {
		[CHMURLProtocol unregisterContainer:_container];
    }
}

#pragma mark Preferences
- (void) readPreferences
{
	KEY_savedBookmarks = [KEY_savedBookmarks stringByAppendingString:[_container uniqueId]];
	NSDictionary *savedBookmarks = [[NSUserDefaults standardUserDefaults] dictionaryForKey: KEY_savedBookmarks];
	if (savedBookmarks == nil){
		bookmarks = [[NSMutableDictionary alloc] init];
	} else{
		bookmarks = [[NSMutableDictionary alloc] initWithDictionary:savedBookmarks];
        [__bookKeys addObjectsFromArray:[bookmarks allKeys]];
	}
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *appDefaults = [NSDictionary dictionaryWithObject:bookmarks forKey:KEY_savedBookmarks];
	[defaults registerDefaults:appDefaults];
	
}

#pragma mark NSDocument

- (void)makeWindowControllers
{
    _windowController = [[CHMWindowController alloc] initWithWindowNibName:@"CHMDocument"];
    [self addWindowController:_windowController];
	[_windowController setDocument: self];
}


- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)docType {
    //NSLog( @"CHMDocument:readFromFile:%@", fileName );
    
    _container = [[CHMContainer alloc] initWithContentsOfFile:fileName];
    if( !_container ) return NO;
	
    [CHMURLProtocol registerContainer:_container];
    _tableOfContents = [[CHMTableOfContents alloc] initWithContainer:_container];

	[self readPreferences];
	[self openIndex];
    return YES;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError * _Nullable *)outError
{
    // Viewer only
    //if (outError) {
    //    *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:nil];
    //}
    return nil;
}


#pragma mark CHM operations
- (NSURL *)urlForSelectedSearchResult: (NSUInteger)selectedIndex
{
	id target = [searchResults objectForKey:[__searchKeys objectAtIndex:selectedIndex]];
	return [NSURL URLWithString:target];
}

- (NSUInteger) searchResultsCount
{
	return [searchResults count];
}

- (id) searchResultAtIndex: (NSUInteger) requestedIndex
{
	return [__searchKeys objectAtIndex:requestedIndex];
}


#pragma mark Bookmark operations
- (void)addBookmark
{
	if (lastLoadedPage != nil) {
        [__bookKeys addObject:lastLoadedPageName];
		[bookmarks setObject:lastLoadedPage forKey:lastLoadedPageName];
		[[NSUserDefaults standardUserDefaults] setObject:bookmarks forKey:KEY_savedBookmarks];
	}
}

- (void)removeBookmark: (NSUInteger)bookmarkIndex
{
    NSString *toRemove = [__bookKeys objectAtIndex:bookmarkIndex];
	[bookmarks removeObjectForKey:toRemove];
    [__bookKeys removeObject:toRemove];
	[[NSUserDefaults standardUserDefaults] setObject:bookmarks forKey:KEY_savedBookmarks];
}

- (NSUInteger) bookmarkCount
{
	return [bookmarks count];
}

- (NSString *) bookmarkURLAtIndex: (NSUInteger) selectedIndex;
{
	return [bookmarks objectForKey: [__bookKeys objectAtIndex:selectedIndex]];
}

- (NSString *) bookmarkTitleAtIndex: (NSUInteger) selectedIndex;
{
	return [__bookKeys objectAtIndex:selectedIndex];
}


#pragma mark Search operations
//..........................................................................

// specify the maximum number of hits
#define kSearchMax 1000

/**
 * The main search method.
 * This method is responsible for searching ...
 * TODO: finish
 */
- (void) search:(NSString *)query
{
	searchResults = [[NSMutableDictionary alloc] init];
    __searchKeys = [[NSMutableOrderedSet alloc] init];
	//..........................................................................
	// set up search options
    SKSearchOptions options = kSKSearchOptionDefault;
    //if ([searchOptionNoRelevance intValue]) options |= kSKSearchOptionNoRelevanceScores;
    //if ([searchOptionSpaceIsOR intValue]) options |= kSKSearchOptionSpaceMeansOR;
    //if ([searchOptionSpaceFindSimilar intValue]) options |= kSKSearchOptionFindSimilar;
	
	//..........................................................................
	// create an asynchronous search object 
    SKSearchRef search = SKSearchCreate (skIndex, (__bridge CFStringRef) query, options);
	
	//..........................................................................
	// get matches from a search object
    Boolean more = true;
    UInt32 totalCount = 0;
	
    while (more) {
        SKDocumentID    foundDocIDs [kSearchMax];
        float           foundScores [kSearchMax];
        SKDocumentRef   foundDocRefs [kSearchMax];
        float * scores;
        Boolean unranked = (bool)(options & kSKSearchOptionNoRelevanceScores);
		
        if (unranked) {
            scores = NULL;
        } else {
            scores = foundScores;
        }
		
        CFIndex foundCount = 0;
        CFIndex pos;
		int timeOutInSeconds = 1;
        more =    SKSearchFindMatches (search, kSearchMax, foundDocIDs, scores, timeOutInSeconds, &foundCount);
        totalCount += foundCount;
		
		//..........................................................................
		// get document locations for matches and display results.
		//     alternatively, you can collect results over iterations of this loop
		//     for display later.
        SKIndexCopyDocumentRefsForDocumentIDs(skIndex, foundCount, (SKDocumentID*)foundDocIDs,
                                              (SKDocumentRef*)foundDocRefs);
		
        for (pos = 0; pos < foundCount; pos++) {
            SKDocumentRef doc = (SKDocumentRef) foundDocRefs [pos];
            NSURL* url = (NSURL*)CFBridgingRelease(SKDocumentCopyURL(doc));
            NSString* urlStr = [url absoluteString];
            NSString* desc;
            CFRelease(doc);
			
            if (unranked) {
                desc = [NSString stringWithFormat: @"---\nDocID: %d, URL: %@", (int) foundDocIDs [pos], urlStr];
            } else {
                desc = [NSString stringWithFormat: @"---\nDocID: %d, Score: %f, URL: %@", (int) foundDocIDs[ pos], foundScores [pos], urlStr];
            }
            NSLog(@"%@", desc);
			NSString* entries = [docTitles objectForKey:urlStr ];
			[searchResults setValue:urlStr forKey:entries ];
            [__searchKeys addObject:entries];
        }
    }
    CFRelease(search);
	
    NSString * desc = [NSString stringWithFormat: @"\"%@\" - %d matches", query, (int) totalCount];
	NSLog(@"%@", desc);
}

- (void) addDocWithTextForURL: (NSURL *) aURL
{
    SKDocumentRef doc = SKDocumentCreateWithURL((__bridge CFURLRef) aURL);
	
	NSString* path = [aURL relativePath];
    NSString * contents = [_container stringWithContentsOfObject: path];
    SKIndexAddDocumentWithText(skIndex, doc, (__bridge CFStringRef)contents, true);
    CFRelease(doc);
}

- (void) populateIndexWithSubTopic: (CHMTopic *)aTopic
{
	[self addDocWithTextForURL: [aTopic location]];
    NSString *keyName = [[aTopic location] absoluteString];
    [__searchKeys addObject:keyName];
	[docTitles setValue:[aTopic name] forKey:keyName ];
	for (NSInteger topicIndex = 0; topicIndex < [aTopic countOfSubTopics]; topicIndex++) {
		[self populateIndexWithSubTopic: [aTopic objectInSubTopicsAtIndex: topicIndex]];
	}
}

- (void) populateIndex
{
	NSArray* topics = [_tableOfContents rootTopics];
    
    for (CHMTopic* aTopic in topics) {
		[self populateIndexWithSubTopic: aTopic];
	}
	SKIndexFlush(skIndex);
}

- (void) createNewIndexAtPath:(NSString *)path
{
    NSFileManager *fm = [NSFileManager defaultManager];
	NSString* parentDirectory = [path stringByDeletingLastPathComponent];
	if (![fm fileExistsAtPath:parentDirectory]) {
        [fm createDirectoryAtPath:parentDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
	}
	[fm createFileAtPath:path contents:nil attributes:nil];
    NSURL* url = [NSURL fileURLWithPath: path];
    SKIndexType type = kSKIndexInverted;
    skIndex = SKIndexCreateWithURL((__bridge CFURLRef)url, CFSTR("PrimaryIndex"), type, NULL);
	NSLog(@"New index: %@", skIndex);
	[self populateIndex];
}

- (void) openIndex
{
	NSString* basePath = [@"~/Library/Application Support/Chmox/" stringByExpandingTildeInPath];
	NSString* documentName = [[[_container path] stringByDeletingPathExtension] lastPathComponent];
	NSString* path = [basePath stringByAppendingPathComponent: documentName ];
    NSString* tocPath = [path stringByAppendingPathExtension: @"tt"];
	path = [path stringByAppendingPathExtension:@"idx"];
	if ([[NSFileManager defaultManager] fileExistsAtPath: path]) {
		NSURL* url = [NSURL fileURLWithPath:path];
		// open the specified index
		skIndex = SKIndexOpenWithURL((__bridge CFURLRef)url, CFSTR("PrimaryIndex"), true);
		docTitles = [NSMutableDictionary dictionaryWithContentsOfFile: tocPath];
	} else {
		docTitles = [[NSMutableDictionary alloc] init];
		[self createNewIndexAtPath: path];
		[docTitles writeToFile:tocPath atomically:TRUE];
	}
	
//	[basePath autorelease];
//	[documentName autorelease];
//	[path autorelease];
}

-(void) closeIndex
{
    if (skIndex) {
        SKIndexClose (skIndex);
        skIndex = nil;
    }
}


#pragma mark Accessors

- (NSString *)title
{
    return [_container title];
}

- (NSURL *)currentLocation
{
    return [CHMURLProtocol URLWithPath:[_container homePath] inContainer:_container];
}

@synthesize tableOfContents = _tableOfContents;

- (NSString *)uniqueId
{
    return [_container uniqueId];
}

@synthesize container = _container;
@synthesize lastLoadedPage;
@synthesize lastLoadedPageName;

@end
