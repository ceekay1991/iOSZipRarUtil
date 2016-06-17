//
//  BDCompressUtil.m
//  ArchiveUnArchiveIniOS
//
//  Created by ceekay1991 on 15/8/6.
//  Copyright (c) 2015年 MyCompany Inc. All rights reserved.
//

#import "BDCompressUtil.h"
#import "BDFileUtil.h"
#import "SSZipArchive.h"
#import "UnrarKit.h"
#import "ZipZap.h"


typedef NS_ENUM(int, BDCompressFileType) { BDCompressFileTypeZip, BDCompressFileTypeRar, BDCompressFileTypeUnknow };

typedef void (^BDCompressHandlerPwdBlock)(NSString *pwd);
@interface BDCompressUtil () <UIAlertViewDelegate, SSZipArchiveDelegate> {
    BDCompressHandlerPwdBlock _pwdBlock;
}

- (void)reCompressToZIPWitthSourcePath:(NSString *)source
                    andDestenationPath:(NSString *)destenation
                             andFinish:(void (^)(NSString *filePath))finishBlock;

- (BOOL)unRARfileWithInput:(NSString *)inputFilePath andOutPutPath:(NSString *)outpath pwd:(NSString *)pwd;
- (BOOL)unZipFile:(NSString *)destenation source:(NSString *)source pwd:(NSString *)pwd;
- (BOOL)zipFileWithInput:(NSString *)input andOutput:(NSString *)output;
- (void)unCompressWithSourcePath:(NSString *)source
                 destenationPath:(NSString *)destenation
                 andRemoveSource:(BOOL)remove
                    andRecursion:(BOOL)recursion
                       andFinish:(void (^)())finish;
@end

@implementation BDCompressUtil
- (NSString *)getOutPutpath:(NSString *)source andDestenationPath:(NSString *)destenation {
    NSString *nameWithOutExtension = [self fileNameWithInPutPath:source];
    NSString *outpath = [destenation stringByAppendingFormat:@"/%@", nameWithOutExtension];
    NSLog(@"%@", outpath);
    return outpath;
}
- (BOOL)isCompressFile:(NSString *)input {
    BDCompressFileType type = [self compressFileTypeWithFilePath:input];
    return type != BDCompressFileTypeUnknow;
}

- (void)showPassWordView:(NSString *)title callBack:(BDCompressHandlerPwdBlock)callBack {
    if (callBack) {
        _pwdBlock = callBack;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                        message:nil
                                                       delegate:self
                                              cancelButtonTitle:@"取消"
                                              otherButtonTitles:@"确定", nil];
        alert.alertViewStyle = UIAlertViewStyleSecureTextInput;
        [alert show];
    });
}
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    NSString *pwd = nil;
    if (buttonIndex != alertView.cancelButtonIndex) {
        pwd = [alertView textFieldAtIndex:0].text;
    }

    if (_pwdBlock) {
        _pwdBlock(pwd);
        //_pwdBlock = nil;
    }
}
- (BOOL)unZipFile:(NSString *)destenation source:(NSString *)source pwd:(NSString *)pwd {
    BOOL succed = NO;
    if (pwd) {
        succed = [SSZipArchive unzipFileAtPath:source
                                 toDestination:destenation
                                     overwrite:YES
                                      password:pwd
                                         error:nil
                                      delegate:self];
    } else {
        succed = [SSZipArchive unzipFileAtPath:source toDestination:destenation delegate:self];
    }
    return succed;
}

- (void)unCompressWithSourcePath:(NSString *)source
                 destenationPath:(NSString *)destenation
                             pwd:(NSString *)pwd
                 andRemoveSource:(BOOL)remove
                    andRecursion:(BOOL)recursion

{
    BDCompressFileType type = [self compressFileTypeWithFilePath:source];
    if ([self compressFileTypeWithFilePath:source] != BDCompressFileTypeUnknow) {
        BOOL succed = NO;

        switch (type) {
        case BDCompressFileTypeRar: {
            succed = [self unRARfileWithInput:source andOutPutPath:destenation pwd:pwd];
        } break;
        case BDCompressFileTypeZip: {
            succed = [self unZipFile:destenation source:source pwd:pwd];
        } break;
        default:
            break;
        }
        if (remove) {
            [BDFileUtil deleteFileWithName:source error:nil];
        }
        if (recursion) {
            [self recursionUnCompress:destenation];
        }
    }
}
- (BOOL)rarFileHasPassword:(NSString *)source {
    URKArchive *archive = [URKArchive rarArchiveAtPath:source];
    return [archive isPasswordProtected];
}
- (BOOL)pwdCorrentOfrarFile:(NSString *)source pwd:(NSString *)pwd {
    URKArchive *archive = [URKArchive rarArchiveAtPath:source password:pwd];
    return [archive validatePassword];
}
- (BOOL)pwdCorrentOfZipFile:(NSString *)source pwd:(NSString *)pwd {
    return [SSZipArchive pwdIsCorrect:pwd ofFile:source];
}

- (BOOL)isEncrypted:(NSString *)source type:(BDCompressFileType)type {
    BOOL isEncrypt = NO;
    switch (type) {
    case BDCompressFileTypeRar: {
        isEncrypt = [self rarFileHasPassword:source];
    } break;
    case BDCompressFileTypeZip: {
        isEncrypt = [SSZipArchive UnzipIsEncrypted:source];
    } break;
    default:
        break;
    }
    return isEncrypt;
}

- (BOOL)isPwdCorrect:(NSString *)pwd source:(NSString *)source type:(BDCompressFileType)type {
    BOOL isCorrect = NO;
    switch (type) {
    case BDCompressFileTypeRar: {
        isCorrect = [self pwdCorrentOfrarFile:source pwd:pwd];
    } break;
    case BDCompressFileTypeZip: {
        isCorrect = [self pwdCorrentOfZipFile:source pwd:pwd];
    } break;
    default:
        break;
    }
    return isCorrect;
}

- (void)unCompressWithPwd:(void (^)())finish
                recursion:(BOOL)recursion
                   remove:(BOOL)remove
              destenation:(NSString *)destenation
                   source:(NSString *)source
                     type:(BDCompressFileType)type
               alertTitle:(NSString *)alertTitle {
    __weak typeof(self) weakSelf = self;
    [self showPassWordView:alertTitle
                  callBack:^(NSString *pwd) {
                      __strong typeof(weakSelf) strongSelf = weakSelf;
                      //没有输入密码 不解压缩
                      if (!pwd) {
                          if (finish) {
                              finish();
                          }
                      } else {
                          BOOL pwdSucced = [self isPwdCorrect:pwd source:source type:type];
                          if (pwdSucced) {
                              [self unCompressWithSourcePath:source
                                             destenationPath:destenation
                                                         pwd:pwd
                                             andRemoveSource:remove
                                                andRecursion:recursion];
                              if (finish) {
                                  finish();
                              }
                          } else {
                              [strongSelf unCompressWithPwd:finish
                                                  recursion:recursion
                                                     remove:remove
                                                destenation:destenation
                                                     source:source
                                                       type:type
                                                 alertTitle:@"密码错误,请重新输入"];
                          }
                      }
                  }];
}

- (void)unCompressWithSourcePath:(NSString *)source
                 destenationPath:(NSString *)destenation
                 andRemoveSource:(BOOL)remove
                    andRecursion:(BOOL)recursion
                       andFinish:(void (^)())finish {
    BDCompressFileType type = [self compressFileTypeWithFilePath:source];

    BOOL isEncrypt = [self isEncrypted:source type:type];
    if (isEncrypt) {
        [self unCompressWithPwd:finish
                      recursion:recursion
                         remove:remove
                    destenation:destenation
                         source:source
                           type:type
                     alertTitle:@"请输入密码"];
    } else {
        [self unCompressWithSourcePath:source
                       destenationPath:destenation
                                   pwd:nil
                       andRemoveSource:remove
                          andRecursion:recursion];
        if (finish) {
            finish();
        }
    }
}
- (void)recursionUnCompress:(NSString *)input {
    NSArray *fileArray = [BDFileUtil getContentsOfDirectoryAtPath:input];
    for (NSString *file in fileArray) {
        NSString *filePath = [input stringByAppendingPathComponent:file];
        BOOL isdir = [BDFileUtil dirExistsAtPath:filePath];
        if (isdir) {
            [self recursionUnCompress:filePath];
        } else {
            NSString *destenation = [self getOutPutpath:filePath andDestenationPath:input];
            [self unCompressWithSourcePath:filePath
                           destenationPath:destenation
                           andRemoveSource:YES
                              andRecursion:YES
                                 andFinish:nil];
        }
    }
}
- (void)convertTextEncode:(NSString *)input {
    NSFileManager *fileManager = nil;
    fileManager = [[NSFileManager alloc] init];
    NSDirectoryEnumerator *dirEnumerator = [fileManager enumeratorAtPath:input];
    NSString *fileName;
    while ((fileName = [dirEnumerator nextObject])) {
        BOOL isDir;
        NSString *fullFilePath = [input stringByAppendingPathComponent:fileName];
        [fileManager fileExistsAtPath:fullFilePath isDirectory:&isDir];
        if (!isDir) {
            NSString *extention = [fullFilePath pathExtension];

            CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                                    (__bridge CFStringRef)(extention), NULL);
            BOOL istext = UTTypeConformsTo(uti, kUTTypeText) == TRUE;
            if (istext) {
                UInt32 index = [BDFileUtil fileEncoding:fullFilePath];
                //规定编码格式
                NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(index);
                NSData *originData = [NSData dataWithContentsOfFile:fullFilePath];
                NSString *strdata = [[NSString alloc] initWithData:originData encoding:enc];
                //在将NSString类型转为NSData
                NSData *resData = [strdata dataUsingEncoding:NSUnicodeStringEncoding];
                [resData writeToFile:fullFilePath atomically:YES];
            }
        }
    }
}
- (BDCompressFileType)compressFileTypeWithFilePath:(NSString *)input {
    BDCompressFileType type = BDCompressFileTypeUnknow;
    NSString *fileName = [input lastPathComponent];
    if ([[fileName lowercaseString] hasSuffix:@".zip"]) {
        type = BDCompressFileTypeZip;
    } else if ([[fileName lowercaseString] hasSuffix:@".rar"]) {
        type = BDCompressFileTypeRar;
    }
    return type;
}
- (void)unCompressWitthSourcePath:(NSString *)source
               andDestenationPath:(NSString *)destenation
                        andFinish:(void (^)(NSString *filePath))finishBlock {
    {
        @autoreleasepool {
            __weak typeof(self) weakSelf = self;

            __block NSString *outFile = nil;
            @try {
                NSString *outpath = [weakSelf getOutPutpath:source andDestenationPath:destenation];

                [self unCompressWithSourcePath:source
                               destenationPath:outpath
                               andRemoveSource:NO
                                  andRecursion:YES
                                     andFinish:^{
                                         if (outpath && [BDFileUtil fileExistsAtPath:outpath]) {
                                             NSInteger count = (NSInteger)[BDFileUtil getAllFilesAtPath:outpath].count;
                                             if (count >= 1) {
                                                 outFile = outpath;
                                                 [self convertTextEncode:outpath];
                                             }

                                             if (finishBlock) {
                                                 finishBlock(outFile);
                                             }
                                         } else {
                                             if (finishBlock) {
                                                 finishBlock(outFile);
                                             }
                                         }
                                     }];
            } @catch (NSException *exception) {
                NSLog(@"unCompressWitthSourcePath:%@", exception);
                if (finishBlock) {
                    NSLog(@"__________%@", outFile);
                    finishBlock(outFile);
                }
            } @finally {
            }
        }
    }
}
- (void)reCompressToZIPWitthSourcePath:(NSString *)source
                    andDestenationPath:(NSString *)destenation
                             andFinish:(void (^)(NSString *filePath))finishBlock {
    @autoreleasepool {
        __weak typeof(self) weakSelf = self;

        __block NSString *zipFile = nil;
        @try {
            NSString *outpath = [self getOutPutpath:source andDestenationPath:destenation];

            [self unCompressWithSourcePath:source
                           destenationPath:outpath
                           andRemoveSource:NO
                              andRecursion:YES
                                 andFinish:^{
                                     if (outpath && [BDFileUtil fileExistsAtPath:outpath]) {
                                         NSInteger count = (NSInteger)[BDFileUtil getAllFilesAtPath:outpath].count;
                                         if (count >= 1) {
                                             NSString *fileName = [weakSelf fileNameWithInPutPath:source];
                                             NSString *zipPath =
                                                 [destenation stringByAppendingFormat:@"/%@.zip", fileName];
                                             BOOL succ = [weakSelf zipFileWithInput:outpath andOutput:zipPath];
                                             if (succ) {
                                                 zipFile = zipPath;
                                             }

                                             if (finishBlock) {
                                                 finishBlock(zipFile);
                                             }
                                             [BDFileUtil deleteDirAtPath:outpath];
                                         } else {
                                             if (finishBlock) {
                                                 finishBlock(zipFile);
                                             }
                                         }
                                     } else {
                                         if (finishBlock) {
                                             finishBlock(zipFile);
                                         }
                                     }
                                 }];
        } @catch (NSException *exception) {
            NSLog(@"reCompressToZIPWitthSourcePath fail:%@", exception);
            if (finishBlock) {
                NSLog(@"__________%@", zipFile);
                finishBlock(zipFile);
            }
        } @finally {
        }
    }
}

- (NSString *)fileNameWithInPutPath:(NSString *)inputFilePath {
    NSString *name = [inputFilePath lastPathComponent];
    NSString *nameWithOutExtension =
        [name stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@".%@", [name pathExtension]]
                                        withString:@""];
    return nameWithOutExtension;
}
- (BOOL)unRARfileWithInput:(NSString *)inputFilePath andOutPutPath:(NSString *)outpath pwd:(NSString *)pwd {
    BOOL ok = [BDFileUtil createDirectoryAtPath:outpath];
    NSError *error = nil;
    if (ok) {
        [[URKArchive rarArchiveAtPath:inputFilePath password:pwd]
            extractFilesTo:outpath
                 overwrite:YES
                  progress:^(URKFileInfo *currentFile, CGFloat percentArchiveDecompressed) {

                  }
                     error:&error];
    }

    return ok && error == nil;
}

- (BOOL)zipFileWithInput:(NSString *)input andOutput:(NSString *)output {
    BOOL res;
    //    if (CurrentDeviceVersion >= 8.0) {
    //        res =
    //        [SSZipArchive createZipFileAtPath:output withContentsOfDirectory:input];
    //    } else {
    res = [self zipFileUseZipZapWithInput:input andOutput:output];
    // }
    return res;
}

- (BOOL)zipFileUseZipZapWithInput:(NSString *)input andOutput:(NSString *)output {
    if ([BDFileUtil fileExistsAtPath:output]) {
        [BDFileUtil deleteDirAtPath:output];
    }
    NSError *error = nil;
    ZZArchive *newArchive = [[ZZArchive alloc] initWithURL:[NSURL fileURLWithPath:output]
                                                   options:@{
                                                       ZZOpenOptionsCreateIfMissingKey : @YES
                                                   }

                                                     error:&error];

    __block NSMutableArray *entries = [NSMutableArray array];
    NSFileManager *fileManager = nil;
    fileManager = [[NSFileManager alloc] init];
    NSDirectoryEnumerator *dirEnumerator = [fileManager enumeratorAtPath:input];
    NSString *fileName;
    while ((fileName = [dirEnumerator nextObject])) {
        BOOL isDir;
        NSString *fullFilePath = [input stringByAppendingPathComponent:fileName];
        [fileManager fileExistsAtPath:fullFilePath isDirectory:&isDir];
        if (!isDir) {
            ZZArchiveEntry *entry = [ZZArchiveEntry
                archiveEntryWithFileName:fileName
                                compress:YES
                               dataBlock:^NSData *(NSError **error) {
                                   NSData *originData = [NSData dataWithContentsOfFile:fullFilePath];

                                   NSString *extention = [fullFilePath pathExtension];

                                   CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(
                                       kUTTagClassFilenameExtension, (__bridge CFStringRef)(extention), NULL);
                                   BOOL istext = UTTypeConformsTo(uti, kUTTypeText) == TRUE;
                                   if (istext) {
                                       UInt32 index = [BDFileUtil fileEncoding:fullFilePath];

                                       //规定编码格式
                                       NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(index);
                                       //将有乱码的 NSMutableData类型 mydata
                                       //转为规定了格式的NSString
                                       //类型 strdata
                                       NSString *strdata = [[NSString alloc] initWithData:originData encoding:enc];
                                       //在将NSString类型转为NSData
                                       NSData *resData = [strdata dataUsingEncoding:NSUnicodeStringEncoding];
                                       if (resData) {
                                           return resData;
                                       }
                                   }
                                   return originData;

                               }];
            [entries addObject:entry];
        }
    }

    [newArchive updateEntries:entries error:&error];
    [entries removeAllObjects];
    entries = nil;
    newArchive = nil;
    return !error;
}
- (NSString *)reEncode:(char *)data {
    UInt32 index = [BDFileUtil fileEncodingOfChar:data];
    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(index);

    NSString *strdata = [NSString stringWithCString:data encoding:enc];
    return strdata;
}
- (NSString *)zipArchiveReEncodeFilename:(char *)filename {
    return [self reEncode:filename];
}
- (void)dealloc {
    NSLog(@"compressUtil dealloc....");
}

+ (BDCompressUtil *)compressUtil {
    BDCompressUtil *util = [[BDCompressUtil alloc] init];
    return util;
}
+ (void)reCompressToZIPWitthSourcePath:(NSString *)source
                    andDestenationPath:(NSString *)destenation
                             andFinish:(void (^)(NSString *filePath))finishBlock {
    [[self compressUtil] reCompressToZIPWitthSourcePath:source andDestenationPath:destenation andFinish:finishBlock];
}

+ (void)unCompressWitthSourcePath:(NSString *)source
               andDestenationPath:(NSString *)destenation
                        andFinish:(void (^)(NSString *filePath))finishBlock {
    [[self compressUtil] unCompressWitthSourcePath:source andDestenationPath:destenation andFinish:finishBlock];
}
+ (BOOL)unRARfileWithInput:(NSString *)inputFilePath andOutPutPath:(NSString *)outpath pwd:(NSString *)pwd {
    return [[self compressUtil] unRARfileWithInput:inputFilePath andOutPutPath:outpath pwd:pwd];
}
+ (void)unCompressWithSourcePath:(NSString *)source
              andDestenationPath:(NSString *)destenation
                 andRemoveSource:(BOOL)remove
                    andRecursion:(BOOL)recursion
                       andFinish:(void (^)())finish {
    [[self compressUtil] unCompressWithSourcePath:source
                                  destenationPath:destenation
                                  andRemoveSource:remove
                                     andRecursion:recursion
                                        andFinish:finish];
}
+ (BOOL)unZipFile:(NSString *)destenation source:(NSString *)source pwd:(NSString *)pwd {
    return [[self compressUtil] unZipFile:destenation source:source pwd:pwd];
}
+ (BOOL)zipFileWithInput:(NSString *)input andOutput:(NSString *)output {
    return [[self compressUtil] zipFileWithInput:input andOutput:output];
}

@end
