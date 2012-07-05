//
//  weiboSearchFriendsViewViewController.m
//  searchbarTest
//
//  Created by 雨骁 刘 on 12-4-13.
//  Copyright (c) 2012年 BUAA. All rights reserved.
//

#import "weiboSearchFriendsViewViewController.h"
#import "sqlService.h"
#import "WBSendView.h"

@interface weiboSearchFriendsViewViewController ()

@end

@implementation weiboSearchFriendsViewViewController

@synthesize theSearchBar;
@synthesize thedisplaycontroller;
@synthesize allItems;
@synthesize searchResults;
@synthesize instanceofTableView;
@synthesize PLViewController;
@synthesize mySendView;
@synthesize tempBtn;


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    //init the searchBar
    theSearchBar = [[UISearchBar alloc]initWithFrame:CGRectMake(0, 0, 320, 40)];
    theSearchBar.delegate = self;
    theSearchBar.showsCancelButton = YES;
    UIColor *barColor = [UIColor colorWithRed:9/255.0 green:125/255.0 blue:244/255.0 alpha:1.0]; 
    theSearchBar.tintColor = barColor;
    [theSearchBar setPlaceholder:@"谁了？"];
    UITextField *tempTextField = [[UITextField alloc]init];
    
    tempBtn = [[UIButton alloc] init];
            
    for(UIView *v in [theSearchBar subviews])
    {
        NSLog(@"the subview of UISearchBar is %@",v);
        if([v isKindOfClass:[UITextField class]])
        {
            tempTextField = (UITextField*)v;
        }
        if ([v isKindOfClass:[UIButton class]]) {
            tempBtn = [(UIButton *)v retain];
        }
    }
    
   // [tempBtn addTarget:self action:@selector(onCancelSearch:) forControlEvents:UIControlEventTouchUpInside];
    
    [tempTextField setKeyboardType:UIKeyboardTypeTwitter];

    
    if (tempTextField) {  
        UIImage *image = [UIImage imageWithContentsOfFile: @"/Library/Application Support/Photo2Weibo/character1.png"];
        UIImageView *iView = [[UIImageView alloc] initWithImage:image];
        iView.frame = CGRectMake(0, 0, 30, 30);
        iView.contentMode = UIViewContentModeScaleAspectFit;
        tempTextField.leftView = iView;
        [iView release];
    } 
    
    [self.view addSubview:theSearchBar];
    
    //init the displayView
    
    thedisplaycontroller = [[UISearchDisplayController alloc] initWithSearchBar:theSearchBar contentsController:self];
    thedisplaycontroller.delegate = self;
    thedisplaycontroller.searchResultsDelegate = self;
    thedisplaycontroller.searchResultsDataSource = self;
    
    [thedisplaycontroller setActive:YES animated:YES];
    [theSearchBar becomeFirstResponder];
    
    instanceofTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 44, 320, 440) style:UITableViewStylePlain];
    [instanceofTableView setDelegate:self];
    [instanceofTableView setDataSource:self];
    
    [self.view addSubview:instanceofTableView];
    
    //init the allItems
     sqlService *sqlSer = [[sqlService alloc] init];
    NSMutableArray *temparray=  [sqlSer getweibofriendList];
   // NSLog(@"the temparray friends list is %@",temparray);
    if([temparray count] == 0){
        NSLog(@"error when read friends list");
    }
    else{
        
        allItems = [[NSArray alloc] initWithArray:temparray];
    
    }

}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{	
	NSLog(@"cancel button press-----------");
    [mySendView setHidden: NO];
    [self dismissViewControllerAnimated:NO 
                             completion:^{
                             }];
    [mySendView textviewFirstResponder];
}

- (void)onCancelSearch:(id)sender
{    
    [mySendView setHidden: NO];
    [self dismissViewControllerAnimated:NO 
                             completion:^{
                             }];
    [mySendView textviewFirstResponder];
}


- (void)dealloc
{
    [thedisplaycontroller setDelegate:nil], thedisplaycontroller = nil;
    [theSearchBar setDelegate:nil],theSearchBar = nil;
    [instanceofTableView setDelegate: nil];
    [instanceofTableView release];
    [tempBtn release];
    instanceofTableView = nil;
    [super dealloc];
}
- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    [thedisplaycontroller setDelegate:nil], thedisplaycontroller = nil;
    [theSearchBar setDelegate:nil],theSearchBar = nil;
}

#pragma mark TableView Data Source Methods

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    if([tableView isEqual:self.searchDisplayController.searchResultsTableView]){
        return [self.searchResults count];
    }
    else {
        return  [allItems count];
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    NSUInteger section = [indexPath section];
//    NSUInteger row = [indexPath row];
    static NSString *SectionsTableIdentifier = @"SectionsTableIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:
                             SectionsTableIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleDefault
                reuseIdentifier:SectionsTableIdentifier];
        //cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    if ([tableView isEqual:self.searchDisplayController.searchResultsTableView]) {
        if([indexPath length]){
            cell.textLabel.text = [self.searchResults objectAtIndex:indexPath.row];
        }
    }
    else {
        if([indexPath length]){
            cell.textLabel.text = [allItems objectAtIndex:indexPath.row];
        }
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

    UITableViewCell *tempCell = [tableView cellForRowAtIndexPath:indexPath];
    NSString *cellText = tempCell.textLabel.text;
    //append it to sendview contenttextview
    NSRange myRange = [cellText rangeOfString:@"("];
    if(myRange.length >0 )
    {
        [mySendView appendContent: [[cellText substringToIndex:myRange.location] stringByAppendingString:@" "]];    
    }
    else
    {
        [mySendView appendContent: [cellText stringByAppendingString:@" "]];    
    }
    [mySendView setHidden: NO];
    [self dismissViewControllerAnimated:NO 
                             completion:^{
                             }];
    [mySendView textviewFirstResponder];
}

- (void)filterContentForSearchText:(NSString*)searchText 
                             scope:(NSString*)scope
{
    NSPredicate *resultPredicate = [NSPredicate 
                                    predicateWithFormat:@"SELF contains[cd] %@",
                                    searchText];
    self.searchResults = [allItems filteredArrayUsingPredicate:resultPredicate];
}

#pragma mark UISearchDisplayController delegate methods
-(BOOL)searchDisplayController:(UISearchDisplayController *)controller 
shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString 
                               scope:[[self.searchDisplayController.searchBar scopeButtonTitles]
                                      objectAtIndex:[self.searchDisplayController.searchBar
                                                     selectedScopeButtonIndex]]];
    
    return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller 
shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    [self filterContentForSearchText:[self.searchDisplayController.searchBar text] 
                               scope:[[self.searchDisplayController.searchBar scopeButtonTitles]
                                      objectAtIndex:searchOption]];
    
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
