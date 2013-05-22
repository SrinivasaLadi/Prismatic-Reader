/*
    ViewController.m
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

#import "ViewController.h"
#import "StoryCell.h"
#import "WebController.h"
#import "RefreshDelegate.h"
#import "RefreshCell.h"
#import "Evaluate.h"
#import "AccelerationAnimation.h"
#import "SKPSMTPMessage.h"
#import "NSData+Base64Additions.h"
#import "AppDelegate.h"
#import "ImagePreloader.h"

#import "MetaTable.h"

#import "SavedStory.h"

static NSString *fromEmail = @"";
static NSString *toEmail   = @"";
static NSString *loginEmail = @"";
static NSString *relayHost = @"";
static NSString *password = @"";

@interface ViewController ()
@property(nonatomic, copy) NSString *nextString;

@property(nonatomic, copy) NSString *url;
@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSDictionary *storyDict;

@end

@implementation ViewController
{
    UITableView *storyTable;
    UITableView *metaTable;
    NSString *documentsDirectory;
    WebController *webController;
    NSMutableArray *storyData;
    NSTimer *doubleSelectPreventionTimer;
    NSInteger index;
    BOOL canTap;
    BOOL offline;
    SKPSMTPMessage *message;
    __weak UIImageView *header;
    NSInteger headerHeight;
    NSInteger tableHeight;
    NSMutableArray *imageIndices;
}

-(void) didSelectMetaOption:(NSString*)option
{
    [self toggleAux];
}

- (void)viewDidLoad
{
    storyData = [NSMutableArray new];
    canTap = YES;
    index = 0;
    
    imageIndices = [NSMutableArray new];
    
    NSInteger screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    UIImageView *hdr = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"PrismaticHeader.png"]];
    header = hdr;
    headerHeight = hdr.frame.size.height;
    
    metaTable = [[MetaTable alloc] initWithFrame:CGRectMake(0, header.frame.size.height-6, 320, screenHeight - 20 - header.frame.size.height+6) style:UITableViewStylePlain delegate:self header:hdr];
    metaTable.hidden = YES;
    metaTable.backgroundColor = [UIColor blackColor];
    [self.view addSubview:metaTable];
    
    storyTable = [[UITableView alloc] initWithFrame:CGRectMake(0, header.frame.size.height-6, 320, screenHeight - 20 - header.frame.size.height) style:UITableViewStylePlain];
    storyTable.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1];
    tableHeight = storyTable.frame.size.height;
    [self.view addSubview:storyTable];
    storyTable.hidden = YES;
    
    self.nextString = nil;
    
    [self.view addSubview:header];

    UIImageView *settingsButton = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"PrismaticSettingsIcon.png"]];
    [header addSubview:settingsButton];
    settingsButton.frame = CGRectMake(0, 1, settingsButton.frame.size.width, settingsButton.frame.size.height);
    settingsButton.userInteractionEnabled = YES;
    header.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *backGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleAux)];
    [backGesture setNumberOfTapsRequired:1];
    [settingsButton addGestureRecognizer:backGesture];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *defaultsDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:fromEmail, @"fromEmail",
                                               toEmail, @"toEmail",
                                               relayHost, @"relayHost",
                                               loginEmail, @"login",
                                               password, @"pass",
                                               [NSNumber numberWithBool:YES], @"requiresAuth",
                                               [NSNumber numberWithBool:YES], @"wantsSecure", nil];
    
    [userDefaults registerDefaults:defaultsDictionary];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"335601628" ofType:@"json"];
    if (filePath)
    {
        NSString *jsonText = [NSString stringWithContentsOfFile:filePath usedEncoding:nil error:nil];
        NSError *error;
        NSArray *storyElements = [NSJSONSerialization JSONObjectWithData:[jsonText dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
        
        NSInteger initialCount = [storyData count];
        
        for(NSDictionary *storyElement in storyElements)
        {
            if(!storyElement[@"next"])
            {
                [storyData addObject:storyElement];
            } else
            {
                self.nextString = storyElement[@"next"];
            }
        }

        if(initialCount == 0 && [storyData count] > 0)
        {
            storyTable.showsVerticalScrollIndicator = NO;
            storyTable.dataSource = self;
            storyTable.delegate = self;
            storyTable.hidden = NO;
            metaTable.hidden = NO;
            [storyTable reloadData];
            return;
        }
    }
    
    offline = NO;
    
    [super viewDidLoad];
}

-(void) toggleAux
{
    if(storyTable.frame.origin.x < 1)
    {
        [UIView animateWithDuration:0.26
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             storyTable.frame = CGRectMake(storyTable.frame.size.width - 220,
                                                                   storyTable.frame.origin.y,
                                                                   storyTable.frame.size.width,
                                                                   storyTable.frame.size.height);
                             header.frame = CGRectMake(header.frame.size.width - 220,
                                                           header.frame.origin.y,
                                                           header.frame.size.width,
                                                           header.frame.size.height);
                             
                             
                         }
                         completion:^(BOOL finished){
                         }
         ];
    } else
    {
        [UIView animateWithDuration:0.26
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             storyTable.frame = CGRectMake(0,
                                                           storyTable.frame.origin.y,
                                                           storyTable.frame.size.width,
                                                           storyTable.frame.size.height);
                             header.frame = CGRectMake(0,
                                                       header.frame.origin.y,
                                                       header.frame.size.width,
                                                       header.frame.size.height);
                             
                             
                         }
                         completion:^(BOOL finished){
                         }
         ];
    }
}

-(void)messageSent:(SKPSMTPMessage *)msg
{
    NSError *error = nil;
    AppDelegate *del = (AppDelegate*)[UIApplication sharedApplication].delegate;
    NSManagedObjectContext *moc = [del managedObjectContext];
    
    SavedStory *story = (SavedStory *)[NSEntityDescription insertNewObjectForEntityForName:@"SavedStory" inManagedObjectContext:moc];
    story.date = [NSDate dateWithTimeIntervalSinceNow:0];
    story.url = self.url;
    story.title = self.title;
    story.type = @"email";
    
    NSError *err = nil;
    NSData *storyDataObj = [NSJSONSerialization dataWithJSONObject:self.storyDict options:0 error:&err];
    story.data = storyDataObj;
    
    SaveAndDLogOnErrorNoErrorDef(@"Could not save story to datastore.");
    
    message.delegate = nil;
    message = nil;
    
    self.url = nil;
    self.title = nil;
    
}
-(void)messageFailed:(SKPSMTPMessage *)msg error:(NSError *)error
{
    self.url = nil;
    self.title = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [storyData count] + 1;
}

-(void) loadMore:(id)payload
{
    NSString *fileID = (NSString*)payload;
    
    if(!fileID || [fileID length] == 0) return;
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:payload ofType:nil];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    documentsDirectory = [paths objectAtIndex:0];
    NSData *fileData = [NSData dataWithContentsOfFile:filePath];

    if(!fileData) return;

    NSError *err = nil;
    NSArray *storyElements = [NSJSONSerialization JSONObjectWithData:fileData options:0 error:&err];

    NSInteger initialCount = [storyData count];

    for(NSDictionary *storyElement in storyElements)
    {
        if(!storyElement[@"next"])
        {
            [storyData addObject:storyElement];
        } else
        {
            self.nextString = storyElement[@"next"];
        }
    }

    NSInteger totalAdded = [storyData count] - initialCount;

    NSMutableArray *indexPaths = [NSMutableArray array];
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(initialCount, totalAdded)];

    [indexSet enumerateIndexesUsingBlock:
     ^(NSUInteger idx, BOOL *stop) {
         [indexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
     }];

    NSMutableArray *deletePaths = [NSMutableArray array];
    [deletePaths addObject:[NSIndexPath indexPathForRow:initialCount inSection:0]];
    [storyTable beginUpdates];
    [storyTable insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    [storyTable endUpdates];
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *StoryCellID = @"StoryCellID";
    static NSString *LoaderCellID = @"LoaderCellID";
 
    StoryCell *cell = (StoryCell*)[tableView dequeueReusableCellWithIdentifier:StoryCellID];
    
    if (cell == nil)
    {
        cell = [[StoryCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:StoryCellID];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.mailDelegate = self;
    }
    
    NSInteger ht = [self tableView:tableView heightForRowAtIndexPath:indexPath];
    [cell setHeight:ht];

    if(indexPath.row == [storyData count])
    {
        //Last element.
        RefreshCell *cell = (RefreshCell*)[tableView dequeueReusableCellWithIdentifier:LoaderCellID];
        
        if (cell == nil)
        {
            cell = [[RefreshCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:LoaderCellID andDelegate:self];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.payload = self.nextString;
        [cell update];
        
        return cell;
    }
    
    NSDictionary *story = [storyData objectAtIndex:indexPath.row];
    [cell update:story index:indexPath.row];
    
    return cell;
}

#pragma mark - Scroll view delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return 0;
}

-(void) enableTap
{
    canTap = YES;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(!canTap)
    {
        return;
    }
    
    canTap = NO;
    doubleSelectPreventionTimer = [NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(enableTap) userInfo:0 repeats:NO];
    
    storyTable.layer.shouldRasterize = YES;
    
    CABasicAnimation* spinAnimation = [CABasicAnimation animation];
    spinAnimation.keyPath = @"transform.scale";
    spinAnimation.fromValue = [NSNumber numberWithFloat:1];
    spinAnimation.toValue = [NSNumber numberWithFloat:.96];
    spinAnimation.duration = .2;
    [CATransaction setCompletionBlock:^ {
        
        storyTable.layer.shouldRasterize = NO;
        
        storyTable.layer.transform = CATransform3DMakeScale(0.96, 0.96, 1);
        
        NSDictionary *story = [storyData objectAtIndex:indexPath.row];
        
        webController = [[WebController alloc] initWithURL:story[@"url"]];
        
        [self addChildViewController:webController];
        [self.view addSubview:webController.view];
        
        webController.view.frame = CGRectMake(self.view.frame.size.width, 0,
                                              self.view.frame.size.width,
                                              self.view.frame.size.height);
        
        __weak __block WebController *weakDetail = webController;
        
        webController.completionBlock = ^(void) {
            
            [UIView animateWithDuration:0.1
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 weakDetail.view.frame = CGRectMake(weakDetail.view.frame.origin.x - 8, weakDetail.view.frame.origin.y,
                                                                 weakDetail.view.frame.size.width + 10,
                                                                    weakDetail.view.frame.size.height);
                                 
                             }
                             completion:^(BOOL finished){
                                 
                                 
                                 [CATransaction begin];
                                 [CATransaction setValue:(id)kCFBooleanFalse forKey:kCATransactionDisableActions];
                                 [CATransaction setValue:[NSNumber numberWithFloat:0.5] forKey:kCATransactionAnimationDuration];
                                 
                                 SecondOrderResponseEvaluator *soe = [[SecondOrderResponseEvaluator alloc] initWithOmega:8 zeta:.8];
                                 
                                 [CATransaction setCompletionBlock:^ {
                                     
                                     [UIView animateWithDuration:0.2
                                                           delay:0.0
                                                         options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction
                                                      animations:^{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
                                                          storyTable.layer.transform = CATransform3DMakeScale(1, 1, 1);
#pragma clang diagnostic pop
                                                      }
                                                      completion:^(BOOL finished){
                                                      }
                                      ];
                                 }];
                                 
                                 AccelerationAnimation *animation =
                                 [AccelerationAnimation
                                  animationWithKeyPath:@"position.x"
                                  startValue:weakDetail.view.layer.position.x
                                  endValue:512
                                  evaluationObject:soe
                                  interstitialSteps:20];
                                 [weakDetail.view.layer setValue:[NSNumber numberWithDouble:512] forKeyPath:@"position.x"];
                                 [weakDetail.view.layer addAnimation:animation forKey:@"position"];
                                 [CATransaction commit];
                                 
                                 
                             }
             ];
        };
        
        [UIView animateWithDuration:0.2
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             webController.view.frame = CGRectMake(0, 0,
                                                                   self.view.frame.size.width,
                                                                   self.view.frame.size.height);
                         }
                         completion:^(BOOL finished){
                         }
         ];
        
        [storyTable.layer removeAllAnimations];
    }];
    spinAnimation.fillMode = kCAFillModeForwards;
    spinAnimation.removedOnCompletion = NO;
    spinAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    [storyTable.layer addAnimation:spinAnimation forKey:@"spinAnimation"];
}

-(void) sendStoryWithTitle:(NSString*)title url:(NSString*)url index:(NSInteger)idx
{
    if([fromEmail isEqualToString:@""])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"Email not configured."
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    self.url = url;
    self.title = title;
    
    message = [[SKPSMTPMessage alloc] init];
    message.fromEmail = [defaults objectForKey:@"fromEmail"];
    
    message.toEmail = [defaults objectForKey:@"toEmail"];
    message.bccEmail = [defaults objectForKey:@"bccEmal"];
    message.relayHost = [defaults objectForKey:@"relayHost"];
    
    message.requiresAuth = [[defaults objectForKey:@"requiresAuth"] boolValue];
    
    if (message.requiresAuth)
    {
        message.login = [defaults objectForKey:@"login"];
        message.pass = [defaults objectForKey:@"pass"];
    }
    
    message.wantsSecure = [[defaults objectForKey:@"wantsSecure"] boolValue]; // smtp.gmail.com doesn't work without TLS!
    
    BOOL found = NO;
    NSInteger i = 0;
    for(NSDictionary *d in storyData)
    {
        if([d[@"title"] isEqualToString:title])
        {
            found = YES;
            break;
        }
        i++;
    }
    
    message.subject = title;
    
    self.storyDict = [storyData objectAtIndex:i];
    
    if(found)
    {
        [storyData removeObjectAtIndex:i];
        
        NSMutableArray *deletePaths = [NSMutableArray array];
        [deletePaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        
        //[deletePaths addObject:[NSIndexPath indexPathForRow:initialCount inSection:0]];
        [storyTable beginUpdates];
        [storyTable deleteRowsAtIndexPaths:deletePaths withRowAnimation:UITableViewRowAnimationAutomatic];
        [storyTable endUpdates];
    }

    message.delegate = self;
    
    NSString *link = [NSString stringWithFormat:@"<a href=\"%@\">%@</a> <br/> <br/> <br/> <br/> Sent via buza's Prismatic client v.01", url, title];
    
    NSDictionary *plainPart = [NSDictionary dictionaryWithObjectsAndKeys:@"text/html",kSKPSMTPPartContentTypeKey,
                               link,kSKPSMTPPartMessageKey,@"8bit",kSKPSMTPPartContentTransferEncodingKey,nil];
    
    message.parts = [NSArray arrayWithObjects:plainPart,nil];
    
    [message send];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)path
{
    static const NSInteger bufferCount = 5;
    ImagePreloader *loader = [ImagePreloader preloader];
    NSArray *indexPaths = [storyTable indexPathsForVisibleRows];
    [imageIndices removeAllObjects];
    [imageIndices addObjectsFromArray:indexPaths];
    NSIndexPath *max = [indexPaths lastObject];
    NSInteger maxRow = max.row;
    
    maxRow = (maxRow >= [storyData count]-2) ? [storyData count]-2 : maxRow+bufferCount;
    
    [loader preloadImages:max.row limit:maxRow data:storyData];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if(indexPath.row == [storyData count])
    {
        return 40;
    }
    
    NSDictionary *story = [storyData objectAtIndex:indexPath.row];
    
    NSInteger titleHeight = [story[@"titleHeight"] integerValue];
    NSInteger bodyHeight = [story[@"bodyHeight"] integerValue];
    NSInteger width = [story[@"width"] integerValue];
    NSInteger height = [story[@"height"] integerValue];
    
    titleHeight = titleHeight < 36 ? 36 : titleHeight;
    
    //No image
    if(width == 0 && height == 0)
    {
        if(NULL_CHECK(story[@"text"]) && [story[@"text"] length] > 0)
        {
            if([story[@"title"] length] > 0)
            {
                return titleHeight + bodyHeight + 10;
            }
        }

        return titleHeight + 16;
    }
    
    //No body
    if(NULL_CHECK(story[@"text"]) && [story[@"text"] length] == 0)
    {
        if(width >= 320)
        {
            CGFloat fract = 320./width;
            
            CGFloat hgt = (fract * height);
            hgt = (fract * height) > MAX_IMG_HEIGHT ? MAX_IMG_HEIGHT : hgt;
            return titleHeight + hgt + TITLE_IMAGE_SPACING + TITLE_IMAGE_PADDING;
        } else
        {
            height = height > MAX_IMG_HEIGHT ? MAX_IMG_HEIGHT : height;
            return height + titleHeight + TITLE_IMAGE_SPACING + TITLE_IMAGE_PADDING;
        }
    }
    
    if(width >= 320)
    {
        CGFloat fract = 320./width;
        
        CGFloat hgt = (fract * height);
        hgt = (fract * height) > MAX_IMG_HEIGHT ? MAX_IMG_HEIGHT : hgt;
        return titleHeight + hgt + TITLE_IMAGE_SPACING + TITLE_IMAGE_PADDING;
    }
    
    return titleHeight + bodyHeight + 2;

}

@end
