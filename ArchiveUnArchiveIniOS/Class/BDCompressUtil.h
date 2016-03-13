//
//  BDCompressUtil.h
//  ArchiveUnArchiveIniOS
//
//  Created by ceekay1991 on 15/8/6.
//  Copyright (c) 2015年 MyCompany Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BDCompressUtil : NSObject
+ (void)reCompressToZIPWitthSourcePath:(NSString *)source
                    andDestenationPath:(NSString *)Odestenation
                             andFinish:(void (^)(NSString *filePath))finishBlock;
+ (void)unCompressWitthSourcePath:(NSString *)source
               andDestenationPath:(NSString *)destenation
                        andFinish:(void (^)(NSString *filePath))finishBlock;

+ (void)unCompressWithSourcePath:(NSString *)source
              andDestenationPath:(NSString *)destenation
                 andRemoveSource:(BOOL)remove
                    andRecursion:(BOOL)recursion
                       andFinish:(void (^)())finish;

+ (BOOL)unRARfileWithInput:(NSString *)inputFilePath andOutPutPath:(NSString *)outpath pwd:(NSString *)pwd;

+ (BOOL)unZipFile:(NSString *)destenation source:(NSString *)source pwd:(NSString *)pwd;

+ (BOOL)zipFileWithInput:(NSString *)input andOutput:(NSString *)output;
@end
