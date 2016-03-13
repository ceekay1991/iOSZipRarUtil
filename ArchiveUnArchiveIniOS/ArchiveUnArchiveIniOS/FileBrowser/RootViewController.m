//
//  RootViewController.m
//  FileBrowser
//
//  Created by Kobe Dai on 10/24/12.
//  Copyright (c) 2012 Kobe Dai. All rights reserved.
//

#import "RootViewController.h"
#import "FileViewController.h"

@interface RootViewController ()
{
    NSString *creationDate;
    NSString *modificationDate;
    NSArray *contentsDirectory;
}

@end

@implementation RootViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSString *currentPath = [self.fm currentDirectoryPath];
    
    NSDictionary *currentDitionary = [self.fm attributesOfItemAtPath: currentPath error: nil];
    creationDate = [[currentDitionary valueForKey: NSFileCreationDate] description];
    modificationDate = [[currentDitionary valueForKey: NSFileModificationDate] description];
    contentsDirectory = [self.fm contentsOfDirectoryAtPath: currentPath error: nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];
    
    if (self.isPoped)
    {
        [self.fm changeCurrentDirectoryPath: self.previousPath];
        self.isPoped = NO;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0 || section == 1)
    {
        return 1;
    }
    else
    {
        return [contentsDirectory count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *ContentsCellIdentifier = @"ContentsCell";
    static NSString *DateCellIdentifier = @"DateCell";
    UITableViewCell *contentsCell = [tableView dequeueReusableCellWithIdentifier:ContentsCellIdentifier];
    UITableViewCell *dateCell = [tableView dequeueReusableCellWithIdentifier: DateCellIdentifier];
    if (contentsCell == nil)
    {
        contentsCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ContentsCellIdentifier];
    }
    if (dateCell == nil)
    {
        dateCell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: DateCellIdentifier];
    }
    
    int section = [indexPath section];
    int row = [indexPath row];
    
    if (section == 0)
    {
        dateCell.textLabel.text = creationDate;
        return dateCell;
    }
    else if (section == 1)
    {
        dateCell.textLabel.text = modificationDate;
        return dateCell;
    }
    else
    {
        contentsCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        contentsCell.textLabel.text = [contentsDirectory objectAtIndex: row];
        return contentsCell;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        return @"Creation Date";
    }
    else if (section == 1)
    {
        return @"Modification Date";
    }
    else
    {
        return @"Contents";
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath section] != 0 && [indexPath section] != 1)
    {
        // Check whether it is a directory or a folder
        NSString *selectedPath = [contentsDirectory objectAtIndex: [indexPath row]];
        NSString *prePath = [self.fm currentDirectoryPath];
        BOOL flag = [self.fm changeCurrentDirectoryPath: selectedPath];
        
        // It is a directory
        if (flag)
        {
            RootViewController *rootViewController = [[RootViewController alloc] initWithNibName: @"RootViewController" bundle: nil];
            rootViewController.fm = self.fm;
            rootViewController.title = selectedPath;
            
            self.previousPath = prePath;
            self.isPoped = YES;
            [self.navigationController pushViewController: rootViewController animated: YES];
        }
        // It is a file
        else
        {
            FileViewController *fileViewController = [[FileViewController alloc] initWithNibName: @"FileViewController" bundle: nil];
            NSString *path = selectedPath;
            NSDictionary *file = [self.fm attributesOfItemAtPath: path error: nil];
            
            fileViewController.creationDate = [[file valueForKey: NSFileCreationDate] description];
            fileViewController.modificationDate = [[file valueForKey: NSFileModificationDate] description];
            fileViewController.fileSize = [NSString stringWithFormat: @"%@", [file valueForKey: NSFileSize]];
            fileViewController.title = selectedPath;
            
            [self.navigationController pushViewController: fileViewController animated: YES];
        }
    }
    
    [tableView deselectRowAtIndexPath: indexPath animated: YES];
}

@end
