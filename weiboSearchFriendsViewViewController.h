//
//  weiboSearchFriendsViewViewController.h
//  searchbarTest
//
//  Created by 雨骁 刘 on 12-4-13.
//  Copyright (c) 2012年 BUAA. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface weiboSearchFriendsViewViewController : UIViewController <UISearchDisplayDelegate,UISearchBarDelegate,UITableViewDelegate,UITableViewDataSource>{
    
    UISearchBar *theSearchBar;
    UISearchDisplayController *thedisplaycontroller;
    NSArray *searchResults;
    NSArray *allItems;
    UITableView *instanceofTableView;
    UIButton *tempBtn;
}

@property (nonatomic, retain) UITableView *instanceofTableView;
@property (nonatomic, retain) UISearchBar *theSearchBar;
@property (nonatomic,retain) UISearchDisplayController *thedisplaycontroller;
@property (nonatomic, retain) NSArray *searchResults;
@property (nonatomic,retain) NSArray *allItems;
@property (nonatomic,retain) id PLViewController;
@property (nonatomic,retain) id mySendView;
@property (nonatomic,retain) UIButton *tempBtn;

- (void)onCancelSearch:(id)sender;
@end
