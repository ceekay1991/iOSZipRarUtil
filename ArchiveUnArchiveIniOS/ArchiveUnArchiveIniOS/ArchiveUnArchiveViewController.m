//
//  ArchiveUnArchiveViewController.m
//  ArchiveUnArchiveIniOS
//
//  Created by ceekay1991 on 15/9/11.
//  Copyright (c) 2015年 com.crh.objc. All rights reserved.
//

#import "ArchiveUnArchiveViewController.h"

#import "BDCompressUtil.h"
#import "BDFileUtil.h"
#import "RootViewController.h"
#pragma warming 请修改自己的输出目录
//static NSString *const ArchiveUnArchiveViewControllerOutPath = @"/Users/test";
#define ArchiveUnArchiveViewControllerOutPath [BDFileUtil getDocumentPath]

@interface ArchiveUnArchiveViewController ()

@property (nonatomic, strong) NSArray *documents;
@property (nonatomic, strong) RootViewController *rootViewController;
@end

@implementation ArchiveUnArchiveViewController {
    BDCompressUtil *util;
    UIDocumentInteractionController *documentationInteractionController;
}

- (void)unCompressFile:(NSString *)path {
    
    [self unCompressFile:path showWithPreVC:NO];
}
- (void)unCompressFile:(NSString *)path showWithPreVC:(BOOL)usePreVC {
    
    [self showLoading];
    [BDFileUtil deleteDirAtPath:[ArchiveUnArchiveViewControllerOutPath
                                    stringByAppendingString:[[path lastPathComponent] stringByDeletingPathExtension]]];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [BDCompressUtil unCompressWitthSourcePath:path
                               andDestenationPath:ArchiveUnArchiveViewControllerOutPath
                                        andFinish:^(NSString *filePath) {
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                NSLog(@"unCompressFile 输出目录:%@", filePath);
                                                [self stopLoading];
                                                if (usePreVC) {
                                                    [self openDictoryWithQLPreVC:filePath];
                                                } else {
                                                    [self openDictory:filePath];
                                                }

                                            });

                                        }];
    });
}
- (void)openFile:(NSString *)path {
    if (!path) {
        return;
    }
    NSURL *documentURL = [NSURL fileURLWithPath:path isDirectory:NO];
    documentationInteractionController = [UIDocumentInteractionController interactionControllerWithURL:documentURL];
    documentationInteractionController.delegate = self;
    [documentationInteractionController presentPreviewAnimated:YES];
}

- (void)openDictoryWithQLPreVC:(NSString *)path {
    NSArray *files = [BDFileUtil getAllFilesURLAtPath:path];
    self.documents = files;
    if (self.documents.count > 0) {
        QLPreviewController *qlpreviewVC = [[QLPreviewController alloc] init];
        qlpreviewVC.delegate = self;
        qlpreviewVC.dataSource = self;
        qlpreviewVC.currentPreviewItemIndex = 0;
        [self.navigationController pushViewController:qlpreviewVC animated:NO];
    }
}
- (void)openDictory:(NSString *)path {
    self.rootViewController = [[RootViewController alloc] initWithNibName:@"RootViewController" bundle:nil];
    self.rootViewController.fm = [NSFileManager defaultManager];
    [self.rootViewController.fm changeCurrentDirectoryPath:path];
    self.rootViewController.title = [path lastPathComponent];
    self.rootViewController.isPoped = NO;
    [self.navigationController pushViewController:self.rootViewController animated:YES];
}
- (void)recompress2zip:(NSString *)filePath {
    [self showLoading];
    [BDFileUtil
        deleteDirAtPath:[ArchiveUnArchiveViewControllerOutPath
                            stringByAppendingString:[[filePath lastPathComponent] stringByDeletingPathExtension]]];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [BDCompressUtil reCompressToZIPWitthSourcePath:filePath
                                    andDestenationPath:ArchiveUnArchiveViewControllerOutPath
                                             andFinish:^(NSString *filePath) {
                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                     NSLog(@"recompress2zip 输出目录:%@", filePath);
                                                     [self stopLoading];
                                                     [self openFile:filePath];
                                                 });

                                             }];
    });
}

- (UIViewController *)documentInteractionControllerViewControllerForPreview:
    (UIDocumentInteractionController *)controller {
    return self;
}

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
    return self.documents.count;
}

- (id<QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {
    return [self.documents objectAtIndex:index];
}
- (IBAction)unrar:(id)sender {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"TestArchive" ofType:@"rar"];
    [self unCompressFile:filePath];
}

- (IBAction)unrarpwd:(id)sender {
    // pwd ronghang
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"phplib" ofType:@"rar"];
    [self unCompressFile:filePath];
}

- (IBAction)unzip:(id)sender {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"rarFolder" ofType:@"zip"];
    [self unCompressFile:filePath];
}

//pwd 1234
//pwd 1234
- (IBAction)unzippwd:(id)sender {
    //NSString *filePath = [[NSBundle mainBundle] pathForResource:@"京北驾校" ofType:@"zip"];
    
    
    [self unCompressFile:[self copyFile2Documents:@"testPwdZip" type:@"zip"]];
}
-(NSString*) copyFile2Documents:(NSString*)fileName type:(NSString *)type
{
    NSFileManager*fileManager =[NSFileManager defaultManager];
    NSError*error;
    NSArray*paths =NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString*documentsDirectory =[paths objectAtIndex:0];
    
    NSString*destPath =[[documentsDirectory stringByAppendingPathComponent:fileName] stringByAppendingFormat:@".%@",type];
    
    
    if(![fileManager fileExistsAtPath:destPath]){
        NSString* sourcePath =[[NSBundle mainBundle] pathForResource:fileName ofType:type];
        [fileManager copyItemAtPath:sourcePath toPath:destPath error:&error];
    }
    return destPath;
}

- (IBAction)rar2zip:(id)sender {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"TestArchive" ofType:@"rar"];
    [self recompress2zip:filePath];
}

- (IBAction)zip2zip:(id)sender {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"rarFolder" ofType:@"zip"];
    [self recompress2zip:filePath];
}

- (IBAction)uncompressEncodeFilename:(id)sender {
    NSString *filePath =
        [[NSBundle mainBundle] pathForResource:@"20150828122745_（tuyiyi.com分享）装逼模式+安卓手机的实时预览PS的APP"
                                        ofType:@"zip"];
    [self unCompressFile:filePath];
}

- (IBAction)uncompressEncodeFileContent:(id)sender {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"顾西爵小说" ofType:@"zip"];
    [self unCompressFile:filePath showWithPreVC:YES];
}

- (IBAction)compressEncodeFileContent:(id)sender {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"顾西爵小说" ofType:@"zip"];
    [self recompress2zip:filePath];
}
- (void)showLoading {
    _loadingMaskView.hidden = NO;
    [_loading startAnimating];
}
- (void)stopLoading {
    [_loading stopAnimating];
    _loadingMaskView.hidden = YES;
}

@end
