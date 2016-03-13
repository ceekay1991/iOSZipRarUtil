//
//  RootViewController.h
//  FileBrowser
//
//  Created by Kobe Dai on 10/24/12.
//  Copyright (c) 2012 Kobe Dai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RootViewController : UITableViewController

@property (strong, nonatomic) NSFileManager *fm;
@property (strong, nonatomic) NSString *previousPath;
@property BOOL isPoped;

@end
