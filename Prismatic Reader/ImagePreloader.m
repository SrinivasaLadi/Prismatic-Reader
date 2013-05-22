/*
    ImagePreloader.m
    Prismatic Reader

    Copyright (c) 2013 BuzaMoto.

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

#import "ImagePreloader.h"
#import "ImageCache.h"

@implementation ImagePreloader
{
    NSMutableDictionary *imageURLs;
}

+(ImagePreloader*) preloader
{
    static dispatch_once_t once;
    static ImagePreloader *_sharedLoader;
    dispatch_once(&once, ^ { _sharedLoader = [[self alloc] init];});
    return _sharedLoader;
}

- (id) init
{
    self = [super init];
    imageURLs = [NSMutableDictionary new];
    return self;
}

//A simple image preloader for loading images in stories that are just offscreen.
-(void) preloadImages:(NSInteger)minRow limit:(NSInteger)max data:(NSArray*)data
{
    for(NSInteger i = minRow; i<max; i++)
    {
        if(i >= [data count]) return;
        
        NSDictionary *storyData = [data objectAtIndex:i];

        if(storyData)
        {
            NSString *url = storyData[@"img"];
            if(!url) continue;
            
            if([imageURLs objectForKey:url])
            {
                continue;
            }
            
            [imageURLs setObject:[NSNull null] forKey:url];
            
            ImageCache *imgCache = [ImageCache sharedCache];
            UIImage *img = [imgCache imageForURL:url];
                    
            if(!img)
            {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSURL *aURL = [NSURL URLWithString:url];
                    NSData *data = [[NSData alloc] initWithContentsOfURL:aURL];
                    UIImage *theImg = [UIImage imageWithData:data];
                    if(theImg)
                    {
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [imageURLs removeObjectForKey:url];
                        });
                        
                        [imgCache saveImageToDiskCache:aURL image:img data:data];
                    }
                });
            }
        }
    }
}

@end
