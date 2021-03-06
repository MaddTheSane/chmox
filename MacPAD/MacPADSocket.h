//
//  MacPADSocket.h
//  MacPAD Version Check
//
//  Created by Kevin Ballard on Sun Dec 07 2003.
//  Copyright (c) 2003-2004 TildeSoft. All rights reserved.
//

#import <Foundation/Foundation.h>

// Result codes
typedef NS_ENUM(NSInteger, MacPADResultCode) {
    kMacPADResultNoNewVersion = 0,  //!< No new version available. Not an error
    kMacPADResultMissingValues,     //!< One or both arguments to performCheck: were nil
    kMacPADResultInvalidURL,        //!< URL was invalid or could not be contacted
    kMacPADResultInvalidFile,       //!< XML file was missing or not well-formed
    kMacPADResultBadSyntax,         //!< Version info was missing from XML file
    kMacPADResultNewVersion         //!< New version is available. Not an error
};

@protocol MacPADSocketNotifications;

@interface MacPADSocket : NSObject {
@private
    NSFileHandle    *_fileHandle;
    NSURL           *_fileURL;
    NSString        *_currentVersion;
    NSString        *_newVersion;
    NSString        *_releaseNotes;
    NSDate          *_releaseDate;
    NSString        *_productPageURL;
    NSMutableString *_buffer;
    NSArray         *_productDownloadURLs;
    int             _contentLength;
    BOOL            _headersReceived;
    BOOL            _statusReceived;
    id<MacPADSocketNotifications> _delegate;
}
// Public methods
- (void)performCheck:(NSURL *)url withVersion:(NSString *)version;
- (void)performCheckWithVersion:(NSString *)version;
- (void)performCheckWithURL:(NSURL *)url;
- (void)performCheck;
@property (nonatomic, strong) id<MacPADSocketNotifications> delegate;
@property (readonly, copy) NSString *currentVersion;
@property (readonly, copy) NSString *newVersion NS_RETURNS_NOT_RETAINED;
@property (readonly, copy) NSString *releaseNotes;
@property (readonly, copy) NSDate *releaseDate;
@property (readonly, copy) NSString *productPageURL;
@property (readonly, copy) NSString *productDownloadURL;
@property (readonly, copy) NSArray<NSString*> *productDownloadURLs;

@end

// Constant strings
extern NSString *const MacPADErrorCode;
extern NSString *const MacPADErrorMessage;
extern NSString *const MacPADNewVersionAvailable;

// NSNotifications
extern NSString *const MacPADErrorOccurredNotification; // @"MacPADErrorCode", @"MacPADErrorMessage"
extern NSString *const MacPADCheckFinishedNotification; // @"MacPADNewVersionAvailable"

@protocol MacPADSocketNotifications <NSObject>
- (void)macPADErrorOccurred:(NSNotification *)aNotification;
- (void)macPADCheckFinished:(NSNotification *)aNotification;
@end
