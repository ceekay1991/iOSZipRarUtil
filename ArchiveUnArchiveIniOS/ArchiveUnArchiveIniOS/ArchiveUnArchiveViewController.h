//
//  ArchiveUnArchiveViewController.h
//  ArchiveUnArchiveIniOS
//
//  Created by ceekay1991 on 15/9/11.
//  Copyright (c) 2015年 com.crh.objc. All rights reserved.
//

#import <QuickLook/QuickLook.h>
#import <UIKit/UIKit.h>
@interface ArchiveUnArchiveViewController : UIViewController <UIDocumentInteractionControllerDelegate,
                                                              QLPreviewControllerDataSource,
                                                              QLPreviewControllerDelegate> {
}
@property (weak, nonatomic) IBOutlet UIView *loadingMaskView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loading;

- (IBAction)unrar:(id)sender;
- (IBAction)unrarpwd:(id)sender;
- (IBAction)unzip:(id)sender;
- (IBAction)unzippwd:(id)sender;
- (IBAction)rar2zip:(id)sender;
- (IBAction)zip2zip:(id)sender;
- (IBAction)uncompressEncodeFilename:(id)sender;
- (IBAction)uncompressEncodeFileContent:(id)sender;
- (IBAction)compressEncodeFileContent:(id)sender;

@end
