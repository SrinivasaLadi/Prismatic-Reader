/*
    MetaTable.m
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

#import "MetaTable.h"
#import "MetaCell.h"
#import "AppDelegate.h"
#import "SavedStory.h"

@implementation MetaTable

- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style delegate:(id)delegate header:(UIImageView*)hdr
{
    self = [super initWithFrame:frame style:style];
    if (self)
    {
        self.header = hdr;
        self.selectionDelegate = delegate;
        self.dataSource = self;
        self.delegate = self;
        [self registerClass:(Class) [MetaCell class] forCellReuseIdentifier:@"MetaCell"];
        self.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    return self;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch(section)
    {
        case(0):
            //All, new, saved.
            return 3;
            break;
        case(1):
            return 2;
            break;
        case(2):
            return 3;
            break;
        default:
            return 0;
            break;
    }
}

#pragma mark - Scroll view delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    const NSInteger headerHeight = 96;
    if(scrollView.contentOffset.y > 48 && scrollView.contentOffset.y < headerHeight)
    {
        self.header.frame = CGRectMake(0, -scrollView.contentOffset.y + 48,
                                       self.header.frame.size.width,
                                       self.header.frame.size.height);
    }
    if(scrollView.contentOffset.y >= headerHeight)
    {
        self.header.frame = CGRectMake(0, -headerHeight + 48,
                                       self.header.frame.size.width,
                                       self.header.frame.size.height);
    }
    if(scrollView.contentOffset.y <= 48)
    {
        self.header.frame = CGRectMake(0, 0,
                                       self.header.frame.size.width,
                                       self.header.frame.size.height);
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"MetaCell";
    MetaCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    switch(indexPath.row)
    {
        case(0):
            [cell updateTitle:@"All"];
            break;
        case(1):
            [cell updateTitle:@"New"];
            break;
        case(2):
        {
            NSError *error = nil;
            AppDelegate *del = (AppDelegate*)[UIApplication sharedApplication].delegate;
            NSManagedObjectContext *moc = [del managedObjectContext];
            
            NSFetchRequest *request = [NSFetchRequest new];
            NSEntityDescription *entity = [NSEntityDescription entityForName:@"SavedStory" inManagedObjectContext:moc];
            [request setEntity:entity];
            
            NSMutableArray *mutableFetchResults = [[moc executeFetchRequest:request error:&error] mutableCopy];
            if (mutableFetchResults == nil)
            {
            }
            
            [cell updateTitle:[NSString stringWithFormat:@"Sent (%d)", [mutableFetchResults count]]];
        }
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    switch(section)
    {
        case(1):
        case(2):
            return 40;
            break;
        default:
            return 0;
            break;
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch(indexPath.row)
    {
        case(0):
            [self.selectionDelegate didSelectMetaOption:@"All"];
            return;
        case(1):
            [self.selectionDelegate didSelectMetaOption:@"New"];
            break;
        default:
            [self.selectionDelegate didSelectMetaOption:@"Sent"];
            break;
    }
    
}

@end
