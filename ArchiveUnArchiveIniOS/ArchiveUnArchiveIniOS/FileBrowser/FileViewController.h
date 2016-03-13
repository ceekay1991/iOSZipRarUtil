//
//  FileViewController.h
//  FileBrowser
//
//  Created by Kobe Dai on 10/24/12.
//  Copyright (c) 2012 Kobe Dai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FileViewController : UITableViewController

@property (retain, nonatomic) NSString *creationDate;
@property (retain, nonatomic) NSString *modificationDate;
@property (retain, nonatomic) NSString *fileSize;

@end
