/*
    MetaCell.m
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

#import "MetaCell.h"

@implementation MetaCell
{
    __weak UILabel *titleLabel;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        UILabel *titleLabel_ = [[UILabel alloc] init];
        titleLabel = titleLabel_;
        
        titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:18];
        titleLabel.textColor = [UIColor colorWithWhite:0.9 alpha:1];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.text = @"";
        titleLabel.frame = CGRectMake(10, 0, 300, 44);
        [self.contentView addSubview:titleLabel];


        
        CALayer *border = [CALayer layer];
        border.backgroundColor = [UIColor colorWithWhite:0.16 alpha:1].CGColor;
        [self.contentView.layer addSublayer:border];
        border.frame = CGRectMake(0, 43, 100, 1);
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

-(void) updateTitle:(NSString*)text
{
    if([text isEqualToString:@"All"])
    {
        CALayer *top = [CALayer layer];
        top.backgroundColor = [UIColor colorWithWhite:0.16 alpha:1].CGColor;
        [self.contentView.layer addSublayer:top];
        top.frame = CGRectMake(0, 0, 100, 1);
    }
    titleLabel.text = text;
}

@end
