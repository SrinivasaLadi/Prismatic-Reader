/*
    RefreshCell.m
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

#import "RefreshCell.h"

@interface RefreshCell()
{
    NSTimer *refreshTimer;
    UIImageView *myRunSpinner;
    __weak id<RefreshDelegate> delegate;
}
@end

@implementation RefreshCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier andDelegate:(id<RefreshDelegate>)del
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) 
    {  
        UIImageView *myRunSpinner_ = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MiniSpinner.png"]];
        
        myRunSpinner = myRunSpinner_;
        myRunSpinner.frame = CGRectMake(ceil(160 - myRunSpinner.frame.size.width/2),
                                        ceil(20 -   myRunSpinner.frame.size.height/2),
                                        myRunSpinner.frame.size.width,
                                        myRunSpinner.frame.size.height);

        [self.contentView addSubview:myRunSpinner];
        self.contentView.backgroundColor = [UIColor whiteColor];
        refreshTimer = nil;
        
        delegate = del;
    }
    return self;
}

-(void) update
{
    [myRunSpinner.layer removeAllAnimations];
    
    [refreshTimer invalidate];
    refreshTimer = [NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(refreshContent) userInfo:0 repeats:NO];
    
    CABasicAnimation* spinAnimation = [CABasicAnimation animation];
    spinAnimation.keyPath = @"transform.rotation.z";
    spinAnimation.fromValue = [NSNumber numberWithFloat: 0.0];
    spinAnimation.toValue = [NSNumber numberWithFloat: 2*M_PI];
    spinAnimation.duration = 1.1;
    spinAnimation.repeatCount = HUGE_VALF;
    spinAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    [myRunSpinner.layer addAnimation:spinAnimation forKey:@"spinAnimation"];
}

-(void) dealloc
{
    [refreshTimer invalidate];
}

-(void) refreshContent
{
    [delegate loadMore:self.payload];
    
    [refreshTimer invalidate];
    refreshTimer = nil;
}

@end
