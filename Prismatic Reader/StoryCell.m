/*
    StoryCell.m
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

#import "CTView.h"
#import "StoryCell.h"
#import "ImageCache.h"
#import "ASIHTTPRequest.h"

#define ICO_DIM 16
#define IMG_FADE_SPEED .2

@interface StoryCell()
@property(readwrite) NSInteger dataIndex;
@property(nonatomic, copy) NSString *icoURL;
@property(nonatomic, copy) NSString *storyURL;
@property(nonatomic, copy) NSString *imageURL;
@property(nonatomic, copy) NSString *storyTitle;
@end

@implementation StoryCell
{
    __weak CTView *titleView;
    __weak CTView *summaryView;
    __weak CALayer *sidebarLayer;
    __weak UIImageView *iconView;
    
    NSInteger width;
    NSInteger height;
    NSInteger bodyHeight;
    NSInteger titleHeight;
    UIImageView *previewView;
    UIView *previewContainer;

    NSTimeInterval startTime;
    ASIHTTPRequest *imgRequest;
    ASIHTTPRequest *icoRequest;
    NSDictionary *titleFormatDictionary;
    NSDictionary *bodyFormatDictionary;
    NSInteger firstX, firstY;
}

+(dispatch_queue_t) dispatchQ
{
    static dispatch_queue_t dispatchQueue = nil;
    if(!dispatchQueue)
    {
        dispatchQueue = dispatch_queue_create("com.buzamoto.prmtc.xtractq", NULL);
    }
    return dispatchQueue;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.contentView.backgroundColor = [UIColor whiteColor];
        
        UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(move:)];
        [panRecognizer setMinimumNumberOfTouches:1];
        [panRecognizer setMaximumNumberOfTouches:1];
        panRecognizer.delegate =  self;
        [self.contentView addGestureRecognizer:panRecognizer];
        
        UIFont *font;
        CTFontRef ctFont;
        font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:15];
        ctFont = CTFontCreateWithName((__bridge CFStringRef) font.fontName, font.pointSize, NULL);
        
        titleFormatDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:(__bridge id)ctFont,
                                    (NSString *)kCTFontAttributeName,
                                    (id)[UIColor colorWithRed:18./255. green:10./255. blue:10./255. alpha:1].CGColor,
                                    kCTForegroundColorAttributeName, nil];
        CFRelease(ctFont);
        
        font = [UIFont fontWithName:@"HelveticaNeue" size:13];
        ctFont = CTFontCreateWithName((__bridge CFStringRef) font.fontName, font.pointSize, NULL);
        bodyFormatDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:(__bridge id)ctFont,
                      (NSString *)kCTFontAttributeName,
                      (id)[UIColor colorWithRed:118./255. green:110./255. blue:110./255. alpha:1].CGColor,
                      kCTForegroundColorAttributeName, nil];

        CFRelease(ctFont);
        CALayer *sidebarlayer = [CALayer layer];
        sidebarLayer = sidebarlayer;
        sidebarlayer.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1].CGColor;

        
        CTView *titleView_ = [[CTView alloc] initWithFrame:CGRectZero];
        titleView = titleView_;
        titleView.backgroundColor = [UIColor whiteColor];
        titleView.frame = CGRectMake(10, 0, 290, 60);
        [self.contentView addSubview:titleView];
        
        sidebarlayer.frame = CGRectMake(0, 11, 2, 10);
        [self.contentView.layer addSublayer:sidebarlayer];
        
        CTView *summaryView_ = [[CTView alloc] initWithFrame:CGRectZero];
        summaryView = summaryView_;
        summaryView.backgroundColor = [UIColor whiteColor];
        summaryView.frame = CGRectMake(10, titleView.frame.size.height- 10, 300, 100);
        [self.contentView addSubview:summaryView];
        
        self.mailDelegate = nil;
        
        UIView *pc = [[UIView alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:pc];
        previewContainer = pc;
        pc.layer.masksToBounds = YES;
        
        UIImageView *iv = [[UIImageView alloc] initWithImage:nil];
        [pc addSubview:iv];
        
        previewView = iv;
        previewView.contentMode = UIViewContentModeScaleAspectFit;
        
        NSMutableDictionary *newActions = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNull null], @"onOrderIn",
                                           [NSNull null], @"onOrderOut",
                                           [NSNull null], @"sublayers",
                                           [NSNull null], @"contents",
                                           [NSNull null], @"bounds",
                                           [NSNull null], @"position",
                                           nil];
        previewView.layer.actions = newActions;
        pc.layer.actions = newActions;
    
        iv = [[UIImageView alloc] initWithImage:nil];
        [self.contentView addSubview:iv];
        iconView = iv;
    }
    return self;
}

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)panGestureRecognizer
{
    if([panGestureRecognizer respondsToSelector:@selector(translationInView:)])
    {
        const CGPoint translation = [panGestureRecognizer translationInView:self.contentView];
        return fabs(translation.y) < fabs(translation.x);
    } else
        return NO;
}

-(void) animationDidFinish
{
    self.contentView.hidden = YES;
    
    if(self.mailDelegate)
    {
        [self.mailDelegate sendStoryWithTitle:self.storyTitle url:self.storyURL index:self.dataIndex];
    }
}

-(void)move:(UIGestureRecognizer*)sender
{
    CGPoint translatedPoint = [(UIPanGestureRecognizer*)sender translationInView:self.contentView];
    
    if ([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateBegan) {
        firstX = [[sender view] center].x;
        firstY = [[sender view] center].y;
    }
    
    translatedPoint = CGPointMake(firstX+translatedPoint.x, firstY);
    
    [[sender view] setCenter:translatedPoint];
    
    if ([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) {
        CGFloat velocityX = (0.2*[(UIPanGestureRecognizer*)sender velocityInView:self.contentView].x);
        
        CGFloat finalX = firstX;
        CGFloat finalY = firstY;
        
        if(firstX+translatedPoint.x > 470)
        {
            CGFloat animationDuration = (ABS(velocityX)*.0002)+.15;
            
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDuration:animationDuration];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector:@selector(animationDidFinish)];
            [[sender view] setCenter:CGPointMake(finalX + self.frame.size.width+2, finalY)];
            [UIView commitAnimations];
        } else
        {
            CGFloat animationDuration = (ABS(velocityX)*.0002)+.2;
            
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDuration:animationDuration];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
            [UIView setAnimationDelegate:self];
            [[sender view] setCenter:CGPointMake(finalX, finalY)];
            [UIView commitAnimations];
        }
    }
}

-(void) dealloc
{
    [imgRequest clearDelegatesAndCancel];
    [icoRequest clearDelegatesAndCancel];
}

- (void)iconLoadFailure:(ASIHTTPRequest *)request
{
    [icoRequest clearDelegatesAndCancel];
    icoRequest = nil;
}

- (void)iconLoadSuccess:(ASIHTTPRequest *)request
{
    dispatch_async([StoryCell dispatchQ], ^{
        if([self.icoURL isEqualToString:[[request originalURL] absoluteString]])
        {
            NSData *imgData = [request responseData];
            UIImage *img = [UIImage imageWithData:imgData];
            
            dispatch_async(dispatch_get_main_queue(), ^{
    
                iconView.image = img;
                iconView.layer.opacity = 0;
                iconView.frame = CGRectMake(self.frame.size.width-ICO_DIM, 10, ICO_DIM, ICO_DIM);

                ImageCache *imgCache = [ImageCache sharedCache];
                [imgCache saveImageToDiskCache:[NSURL URLWithString:self.icoURL] image:img data:imgData];
                
                [UIView animateWithDuration:0.3
                                      delay:0.0
                                    options:UIViewAnimationOptionCurveEaseOut
                                 animations:^{
                                     iconView.layer.opacity = 1;
                                 }
                                 completion:^(BOOL finished){
                                 }
                 ];
            });
        }
    });
}

- (void)imageLoadFailure:(ASIHTTPRequest *)request
{
    [imgRequest clearDelegatesAndCancel];
    imgRequest = nil;
}

- (void)imageLoadSuccess:(ASIHTTPRequest *)request
{
    previewView.hidden = NO;
    previewContainer.hidden = NO;
    previewContainer.layer.opacity = 1;
    
    dispatch_async([StoryCell dispatchQ], ^{
        if([self.imageURL isEqualToString:[[request originalURL] absoluteString]])
        {
            NSData *imgData = [request responseData];
            UIImage *img = [UIImage imageWithData:imgData];
        
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if(width >= 320)
                {
                    CGFloat hgt = (320./width) * height;
                    
                    previewView.image = img;
                    previewView.layer.opacity = 0;
                    
                    previewContainer.frame = CGRectMake(-1, titleView.frame.size.height, 322, hgt > MAX_IMG_HEIGHT ? MAX_IMG_HEIGHT : hgt);
                    previewView.frame = CGRectMake(0, 0, 322, hgt);
                    
                    ImageCache *imgCache = [ImageCache sharedCache];
                    [imgCache saveImageToDiskCache:[NSURL URLWithString:self.imageURL] image:img data:imgData];
                    
                    [UIView animateWithDuration:IMG_FADE_SPEED
                                          delay:0.0
                                        options:UIViewAnimationOptionCurveEaseOut
                                     animations:^{
                                         previewView.layer.opacity = 1;
                                     }
                                     completion:^(BOOL finished){
                                     }
                     ];
                } else
                {
                    previewView.image = img;
                    previewView.layer.opacity = 0;

                    previewContainer.frame = CGRectMake(ceil(160-width/2), titleView.frame.size.height, width, height > MAX_IMG_HEIGHT ? MAX_IMG_HEIGHT : height);
                    previewView.frame = CGRectMake(0, 0, width, height);
                    
                    
                    ImageCache *imgCache = [ImageCache sharedCache];
                    [imgCache saveImageToDiskCache:[NSURL URLWithString:self.imageURL] image:img data:imgData];
                    
 
                }

            });
        }
    });
}

-(void) setHeight:(NSInteger)ht
{
    self.contentView.frame = CGRectMake(self.contentView.frame.origin.x,
                                        self.contentView.frame.origin.y,
                                        self.contentView.frame.size.width,
                                        ht);
}

-(void) requestImage
{
    ImageCache *imgCache = [ImageCache sharedCache];
    if(width >= 320)
    {
        if(NULL_CHECK(self.imageURL))
        {
            UIImage *img = [imgCache imageForURL:self.imageURL];
            if(!img)
            {
                imgRequest = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:self.imageURL]];
                [imgRequest setDelegate:self];
                [imgRequest setDidFinishSelector:@selector(imageLoadSuccess:)];
                [imgRequest setDidFailSelector:@selector(imageLoadFailure:)];
                [imgRequest startAsynchronous];
            } else
            {
                CGFloat fract = 320./width;
                
                CGFloat hgt = fract * height;
                previewView.hidden = NO;
                previewContainer.hidden = NO;
                previewView.layer.opacity = 0;
                previewView.image = img;

                previewContainer.frame = CGRectMake(-1, titleHeight + 16, 322, hgt > MAX_IMG_HEIGHT ? MAX_IMG_HEIGHT : hgt);
                previewView.frame = CGRectMake(0, 0, 322, hgt);
                
                [UIView animateWithDuration:IMG_FADE_SPEED
                                      delay:0.0
                                    options:UIViewAnimationOptionCurveEaseOut
                                 animations:^{
                                     previewView.layer.opacity = 1;
                                 }
                                 completion:^(BOOL finished){
                                 }
                 ];
            }
        }
    } else
    {
        if(NULL_CHECK(self.imageURL) && width > 0 && height > 0)
        {
            UIImage *img = [imgCache imageForURL:self.imageURL];
            if(!img)
            {
                imgRequest = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:self.imageURL]];
                [imgRequest setDelegate:self];
                [imgRequest setDidFinishSelector:@selector(imageLoadSuccess:)];
                [imgRequest setDidFailSelector:@selector(imageLoadFailure:)];
                [imgRequest startAsynchronous];
            } else
            {
                previewView.hidden = NO;
                previewContainer.hidden = NO;
                previewView.image = img;
                previewView.layer.opacity = 0;
                
                previewContainer.frame = CGRectMake(ceil(160-width/2), titleHeight + 16, width, height > MAX_IMG_HEIGHT ? MAX_IMG_HEIGHT : height);
                previewView.frame = CGRectMake(0, 0, width, height);
                
                [UIView animateWithDuration:IMG_FADE_SPEED
                                      delay:0.0
                                    options:UIViewAnimationOptionCurveEaseOut
                                 animations:^{
                                     previewView.layer.opacity = 1;
                                 }
                                 completion:^(BOOL finished){
                                 }
                 ];
            }
        }
    }
}

-(void) update:(NSDictionary*)storyData index:(NSInteger)index
{
    self.contentView.hidden = NO;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    self.dataIndex = index;
    startTime = 0;
    
    //Cancel all pending requests.
    [icoRequest clearDelegatesAndCancel];
    icoRequest = nil;
    [imgRequest clearDelegatesAndCancel];
    imgRequest = nil;
    
    iconView.image = nil;
    previewView.image = nil;
    
    previewContainer.layer.opacity = 0;
    previewView.hidden = YES;
    summaryView.hidden = YES;
    previewContainer.hidden = YES;
    
    self.storyTitle = storyData[@"title"];
    self.storyURL = storyData[@"url"];
    
    NSString *metaString = storyData[@"meta"];
    NSDictionary *meta = nil;
    
    if(metaString)
    {
        NSData *d = [metaString dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        meta = [NSJSONSerialization JSONObjectWithData:d options:0 error:&error];
    }

    dispatch_sync([StoryCell dispatchQ], ^{
        self.imageURL = nil;
        self.imageURL = storyData[@"img"];
        self.icoURL = nil;
        
        if(meta)
        {
            self.icoURL = meta[@"img"];
        }
    });
    
    NSString *text = storyData[@"text"];
    
    width = [storyData[@"width"] integerValue];
    height = [storyData[@"height"] integerValue];
    titleHeight = [storyData[@"titleHeight"] integerValue];
    bodyHeight = [storyData[@"bodyHeight"] integerValue];
    
    NSString *title = storyData[@"title"];
    
    if(NULL_CHECK(title))
    {
        NSMutableAttributedString *syntaxString = [[NSMutableAttributedString alloc] initWithString:title attributes:titleFormatDictionary];
        
        [titleView setText:syntaxString];
        
        sidebarLayer.frame = CGRectMake(sidebarLayer.frame.origin.x, sidebarLayer.frame.origin.y, sidebarLayer.frame.size.width, titleHeight-4);
        
        titleHeight = titleHeight < 36 ? 36 : titleHeight;
        titleView.frame = CGRectMake(titleView.frame.origin.x, titleView.frame.origin.y, titleView.frame.size.width, titleHeight + 20);
    }
    
    ImageCache *imgCache = [ImageCache sharedCache];
    
    if(NULL_CHECK(self.icoURL))
    {
        UIImage *img = [imgCache imageForURL:self.icoURL];
        
        if(!img)
        {
            icoRequest = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:self.icoURL]];
            [icoRequest setDelegate:self];
            [icoRequest setDidFinishSelector:@selector(iconLoadSuccess:)];
            [icoRequest setDidFailSelector:@selector(iconLoadFailure:)];
            [icoRequest startAsynchronous];
        } else
        {
            iconView.image = img;
            iconView.frame = CGRectMake(self.frame.size.width-ICO_DIM, 10, ICO_DIM, ICO_DIM);
        }
    }
    
    if(NULL_CHECK(text) && [text length] > 0)
    {
        if(NULL_CHECK(self.imageURL) && width > 0 && height > 0)
        {
            if(width < 320)
            {
                summaryView.hidden = NO;
                NSMutableAttributedString *syntaxString = [[NSMutableAttributedString alloc] initWithString:text attributes:bodyFormatDictionary];
                
                [summaryView setText:syntaxString];
                summaryView.frame = CGRectMake(summaryView.frame.origin.x, titleHeight + 8, summaryView.frame.size.width, bodyHeight);
                return;
            }
        }
    }
    
    //Image
    if(NULL_CHECK(self.imageURL) && width > 0 && height > 0)
    {
        UIImage *img = [imgCache imageForURL:self.imageURL];
        summaryView.hidden = YES;
        
        if(!img)
        {
            //Only lazy load images when they are not cached, and we have no text body.
            [self performSelector:@selector(requestImage) withObject:nil afterDelay:.4];
            return;
        } else
        {
            previewView.image = img;
            
            previewView.hidden = NO;
            previewContainer.hidden = NO;
            
            if(width >= 320)
            {
                CGFloat fract = 320./width;
                
                CGFloat hgt = fract * height;
                hgt = (fract * height) > MAX_IMG_HEIGHT ? MAX_IMG_HEIGHT : hgt;
                previewContainer.frame = CGRectMake(-1, titleHeight + TITLE_IMAGE_SPACING, 322, hgt);
            } else
            {
                previewContainer.frame = CGRectMake(ceil(160-width/2), titleHeight + TITLE_IMAGE_SPACING, width, height > MAX_IMG_HEIGHT ? MAX_IMG_HEIGHT : height);
            }
            
            previewView.layer.opacity = 0;
            previewContainer.hidden = NO;
            previewContainer.layer.opacity = 1;
            previewView.frame = CGRectMake(0, 0, previewContainer.frame.size.width, previewContainer.frame.size.height);
            
            [UIView animateWithDuration:IMG_FADE_SPEED
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                                 previewView.layer.opacity = 1;
                             }
                             completion:^(BOOL finished){
                             }
             ];
            
            return;
        }
    }

    if(NULL_CHECK(text) && [text length] > 0)
    {
        summaryView.hidden = NO;
        NSMutableAttributedString *syntaxString = [[NSMutableAttributedString alloc] initWithString:text attributes:bodyFormatDictionary];
        
        [summaryView setText:syntaxString];
        summaryView.frame = CGRectMake(summaryView.frame.origin.x, titleHeight + 8, summaryView.frame.size.width, bodyHeight);
    } else
    {
        summaryView.hidden = YES;
        NSMutableAttributedString *syntaxString = [[NSMutableAttributedString alloc] initWithString:@"" attributes:bodyFormatDictionary];
        summaryView.frame = CGRectMake(summaryView.frame.origin.x, titleHeight + 8, summaryView.frame.size.width, bodyHeight);
        [summaryView setText:syntaxString];
        previewView.hidden = NO;
        previewContainer.hidden = NO;
        previewContainer.layer.opacity = 1;
    }
}

@end
