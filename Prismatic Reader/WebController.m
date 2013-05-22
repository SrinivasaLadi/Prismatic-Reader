/*
    WebController.m
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

#import "WebController.h"
#import "Evaluate.h"

@interface WebController ()
@property(nonatomic, copy) NSString *urlString;
@end

@implementation WebController
{
    __weak UIWebView *webView;
    __weak UILabel *titleLabel;
    __weak UIImageView *myRunSpinner;
    __weak UIImageView *backArrow;
    __weak UIImageView *forwardArrow;
}

-(id) initWithURL:(NSString*)url
{
    self = [super init];
    self.urlString = url;
    return self;
}

- (void)viewDidLoad
{

    self.view.backgroundColor = [UIColor whiteColor];
    
    self.view.frame = CGRectMake(0, 0, 320, [UIScreen mainScreen].bounds.size.height);
    UIWebView *wv = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 320, self.view.frame.size.height - 44)];
    webView = wv;
    [self.view addSubview:wv];
    wv.delegate = self;
    wv.scalesPageToFit = YES;
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.urlString]]];
    
    
    //CGRect titleRect = CGRectMake();
    UILabel *titleField = [[UILabel alloc] initWithFrame:CGRectMake(10, 1, 310-44, 44)];
    titleLabel = titleField;
    titleLabel.textColor = [UIColor colorWithWhite:0.12 alpha:1];
    //titleLabel.shadowColor = [UIColor colorWithWhite:0.9 alpha:1];
    //titleLabel.shadowOffset = CGSizeMake(0, 1);
    UIFont *objectTitleFont = [UIFont fontWithName:@"HelveticaNeue-CondensedBold" size:12.0];
    
    
    UIView *top = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height-62, 320, 44)];
    top.backgroundColor = [UIColor colorWithWhite:0.99 alpha:1];
    [self.view addSubview:top];
    
    titleLabel.font = objectTitleFont;
    titleLabel.text = self.urlString;
    [top addSubview:titleLabel];
    
    
    CALayer *border = [CALayer layer];
    border.frame = CGRectMake(0, 0, 320, 2);
    border.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1].CGColor;
    [top.layer addSublayer:border];
    
    UIImageView *cancel = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"CancelButton.png"]];
    cancel.frame = CGRectMake(self.view.frame.size.width - cancel.frame.size.width - 10,
                              ceil(22-cancel.frame.size.height/2),
                              cancel.frame.size.width,
                              cancel.frame.size.height);
    [top addSubview:cancel];
    cancel.userInteractionEnabled = YES;
    top.userInteractionEnabled= YES;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(close:)];
    [top addGestureRecognizer:tapGesture];
    
    
    
    
    UIImageView *myRunSpinner_ = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MiniSpinner.png"]];
    
    
    myRunSpinner = myRunSpinner_;
    myRunSpinner.frame = CGRectMake(ceil(160-myRunSpinner.frame.size.width/2),
                                                  ceil(420/2 - myRunSpinner.frame.size.height/2),
                                                  myRunSpinner.frame.size.width,
                                                  myRunSpinner.frame.size.height);
    
    CABasicAnimation* spinAnimation = [CABasicAnimation animation];
    spinAnimation.keyPath = @"transform.rotation.z";
    spinAnimation.fromValue = [NSNumber numberWithFloat: 0.0];
    spinAnimation.toValue = [NSNumber numberWithFloat: 2*M_PI];
    spinAnimation.duration = 1.1;
    spinAnimation.repeatCount = HUGE_VALF;
    spinAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    [myRunSpinner.layer addAnimation:spinAnimation forKey:@"spinAnimation"];
    [self.view addSubview:myRunSpinner];
    
    webView.layer.opacity = 0;

    
    
    
    
    UIImageView *minimizeArrow_ = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"BackArrowV2.png"]];
    backArrow = minimizeArrow_;
    [self.view addSubview:backArrow];
    backArrow.userInteractionEnabled = YES;
    backArrow.frame = CGRectMake(0,
                                     top.frame.origin.y - 44,
                                     backArrow.frame.size.width,
                                     backArrow.frame.size.height);
    UITapGestureRecognizer *minimizeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backTap:)];
    [backArrow addGestureRecognizer:minimizeTap];
    backArrow.layer.transform = CATransform3DMakeScale(-1, 1, 1);
    backArrow.hidden = YES;
    
    
    UIImageView *fwa = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"BackArrowV2.png"]];
    forwardArrow = fwa;
    [self.view addSubview:forwardArrow];
    forwardArrow.userInteractionEnabled = YES;
    forwardArrow.frame = CGRectMake(320-44,
                                 top.frame.origin.y - 44,
                                 backArrow.frame.size.width,
                                 backArrow.frame.size.height);
    minimizeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(forwardTap:)];
    [forwardArrow addGestureRecognizer:minimizeTap];
    forwardArrow.hidden = YES;
    
    
    [super viewDidLoad];
}

-(void) backTap:(UIGestureRecognizer*)sender
{
    [webView goBack];
    if(![webView canGoBack])
    {
        backArrow.hidden = YES;
    }
    if(![webView canGoForward])
    {
        forwardArrow.hidden = YES;
    }
}

-(void) forwardTap:(UIGestureRecognizer*)sender
{
    [webView goForward];
    if(![webView canGoForward])
    {
        forwardArrow.hidden = YES;
    }
    if(![webView canGoBack])
    {
        backArrow.hidden = YES;
    }
}

-(void) close:(id)sender
{
    
    self.completionBlock();
   
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)webView:(UIWebView *)wv didFailLoadWithError:(NSError *)error
{
    
}


-(void) hideSpinner
{
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         myRunSpinner.layer.opacity = 1;
                     }
                     completion:^(BOOL finished){
                         [UIView animateWithDuration:0.3
                                               delay:0.0
                                             options:UIViewAnimationOptionCurveEaseOut
                                          animations:^{
                                              webView.layer.opacity = 1;
                                          }
                                          completion:^(BOOL finished){
                                              [myRunSpinner removeFromSuperview];
                                          }
                          ];
                     }
     ];
}

- (void)webViewDidFinishLoad:(UIWebView *)wv
{
    static BOOL dispatch = YES;
    
    [self performSelector:@selector(hideSpinner) withObject:nil afterDelay:3];
    
    if(dispatch)
    {
        
        dispatch = NO;
    }
        
    NSString *title = [webView stringByEvaluatingJavaScriptFromString:@"document.title;"];
    titleLabel.text = title;
    
    if([wv canGoBack])
    {
        backArrow.hidden = NO;
    }
    
    if([wv canGoForward])
    {
        forwardArrow.hidden = NO;
    }
    
    if(![webView canGoBack])
    {
        backArrow.hidden = YES;
    }
    if(![webView canGoForward])
    {
        forwardArrow.hidden = YES;
    }
}

@end
