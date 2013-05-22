//
//  ImageCache.m
//  Prismatic Reader
//
//  Created by buza on 8/11/12.
//
//  Modified version of https://github.com/jakemarsh/JMImageCache 
//

/*
 Copyright (c) 2012 Jake Marsh and other contributors.
 
 Permission is hereby granted, free of charge, to any person obtaining
 a copy of this software and associated documentation files (the
 "Software"), to deal in the Software without restriction, including
 without limitation the rights to use, copy, modify, merge, publish,
 distribute, sublicense, and/or sell copies of the Software, and to
 permit persons to whom the Software is furnished to do so, subject to
 the following conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "ImageCache.h"

static NSString *_JMImageCacheDirectory;

static inline NSString *JMImageCacheDirectory() {
	if(!_JMImageCacheDirectory) {
		_JMImageCacheDirectory = [[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches/JMCache"] copy];
	}
    
	return _JMImageCacheDirectory;
}
inline static NSString *keyForURL(NSURL *url) {
	return [url absoluteString];
}
static inline NSString *cachePathForKey(NSString *key) {
    NSString *fileName = [NSString stringWithFormat:@"JMImageCache-%u", [key hash]];
	return [JMImageCacheDirectory() stringByAppendingPathComponent:fileName];
}

ImageCache *_sharedCache = nil;

@interface ImageCache ()
@property (strong, nonatomic) NSOperationQueue *diskOperationQueue;
@end

@implementation ImageCache

@synthesize diskOperationQueue = _diskOperationQueue;

+ (ImageCache*) sharedCache
{
    static dispatch_once_t once;
    static ImageCache *_sharedCache;
    dispatch_once(&once, ^ { _sharedCache = [[self alloc] init];});
    return _sharedCache;
}

- (id) init {
    self = [super init];
    if(!self) return nil;
    
    self.diskOperationQueue = [[NSOperationQueue alloc] init];
    
    [[NSFileManager defaultManager] createDirectoryAtPath:JMImageCacheDirectory()
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:NULL];
	return self;
}

//Either returns nil or the image.
-(UIImage*) imageForURL:(NSString*)urlString
{
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSString *key = keyForURL(url);
    
    if(!key) return nil;
    
    id returner = [super objectForKey:key];
    
    if(returner) {
        return returner;
    } else {
        UIImage *i = [self imageFromDiskForKey:key];
        if(i) [self setImage:i forKey:key];
        
        return i;
    }
    
    return nil;
}

- (void) removeAllObjects
{
    [super removeAllObjects];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSFileManager *fileMgr = [NSFileManager defaultManager];
        NSError *error = nil;
        NSArray *directoryContents = [fileMgr contentsOfDirectoryAtPath:JMImageCacheDirectory() error:&error];
        
        if (error == nil) {
            for (NSString *path in directoryContents) {
                NSString *fullPath = [JMImageCacheDirectory() stringByAppendingPathComponent:path];
                [fileMgr removeItemAtPath:fullPath error:&error];
            }
        }
    });
}

- (void) removeObjectForKey:(id)key
{
    [super removeObjectForKey:key];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSFileManager *fileMgr = [NSFileManager defaultManager];
        NSString *cachePath = cachePathForKey(key);
        
        NSError *error = nil;
        
        BOOL removeSuccess = [fileMgr removeItemAtPath:cachePath error:&error];
        if (!removeSuccess) {
            //Error Occured
        }
    });
}

#pragma mark -
#pragma mark Setter Methods

- (void) setImage:(UIImage *)i forKey:(NSString *)key {
	if (i) {
		[super setObject:i forKey:key];
	}
}
- (void) setImage:(UIImage *)i forURL:(NSURL *)url {
    [self setImage:i forKey:keyForURL(url)];
}
- (void) removeImageForKey:(NSString *)key {
	[super removeObjectForKey:key];
}
- (void) removeImageForURL:(NSURL *)url {
    [self removeImageForKey:keyForURL(url)];
}


#pragma mark -
#pragma mark Disk Writing Operations

- (void) writeData:(NSData*)data toPath:(NSString *)path {
	[data writeToFile:path atomically:YES];
}
- (void) performDiskWriteOperation:(NSInvocation *)invoction {
	NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithInvocation:invoction];
    
	[self.diskOperationQueue addOperation:operation];
}

-(void) saveImageToDiskCache:(NSURL*)url image:(UIImage*)img data:(NSData*)imgData
{
    NSString *key = keyForURL(url);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = imgData;
        UIImage *i = img;
        
        NSString *cachePath = cachePathForKey(key);
        NSInvocation *writeInvocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(writeData:toPath:)]];
        
        [writeInvocation setTarget:self];
        [writeInvocation setSelector:@selector(writeData:toPath:)];
        [writeInvocation setArgument:&data atIndex:2];
        [writeInvocation setArgument:&cachePath atIndex:3];
        
        [self performDiskWriteOperation:writeInvocation];
        [self setImage:i forKey:key];
        
    });
}

- (UIImage *) imageFromDiskForKey:(NSString *)key
{
	UIImage *i = [[UIImage alloc] initWithData:[NSData dataWithContentsOfFile:cachePathForKey(key) options:0 error:NULL]];
	return i;
}

@end
