/*!
 @class
 @abstract 文件操作工具类
 */

#import "BDFileUtil.h"
#import "uchardet.h"
static NSFileManager *iNSFileManager;

@implementation BDFileUtil

+ (NSFileManager *)getNSFileManager {
    if (!iNSFileManager) {
        iNSFileManager = [NSFileManager defaultManager];
    }
    return iNSFileManager;
}

#pragma mark 判断文件是否存在

+ (BOOL)fileExistsAtPath:(NSString *)aPath {
    BOOL result = NO;
    if (aPath) {
        result = [[self getNSFileManager] fileExistsAtPath:aPath];
    }
    return result;
}

#pragma mark 判断文件夹是否存在
+ (BOOL)dirExistsAtPath:(NSString *)aPath {
    BOOL isDir = NO;
    BOOL result = [[self getNSFileManager] fileExistsAtPath:aPath isDirectory:&isDir];
    return result && isDir;
}

#pragma mark 获取上级目录
+ (NSString *)getParentPath:(NSString *)aPath {
    return [aPath stringByDeletingLastPathComponent];
}

#pragma mark 创建目录的上级目录
+ (BOOL)createParentDirectory:(NSString *)aPath {
    //存在上级目录，并且上级目录不存在的创建所有的上级目录
    BOOL result = NO;
    NSString *parentPath = [self getParentPath:aPath];
    if (parentPath && ![self dirExistsAtPath:parentPath]) {
        result = [[self getNSFileManager] createDirectoryAtPath:parentPath
                                    withIntermediateDirectories:YES
                                                     attributes:nil
                                                          error:nil];
    } else if ([self dirExistsAtPath:parentPath]) {
        result = YES;
    }
    return result;
}

#pragma mark 目录下创建文件
+ (BOOL)createFileWithPath:(NSString *)aPath content:(NSData *)aContent {
    NSFileManager *tempFileManager = [self getNSFileManager];
    BOOL result = NO;
    result = [self createParentDirectory:aPath];
    if (result) {
        result = [tempFileManager createFileAtPath:aPath contents:aContent attributes:nil];
    }
    return result;
}

#pragma mark documents下创建文件
+ (BOOL)createFileAtDocumentsWithName:(NSString *)aFilename content:(NSData *)aContent {
    NSString *filePath = [self getFullPathWithName:aFilename];
    BOOL result = [self createFileWithPath:filePath content:aContent];
    return result;
}

#pragma mark 根据文件名称获取documents的文件名的全路径,需要自己释放
+ (NSString *)getFullPathWithName:(NSString *)aFileName {
    return [[self getDocumentPath] stringByAppendingPathComponent:aFileName];
}

#pragma mark 获取documents的全路径
+ (NSString *)getDocumentPath {
    NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *result = [pathArray objectAtIndex:0];
    return result;
}

#pragma mark 删除文件
+ (BOOL)deleteFileWithName:(NSString *)aFileName error:(NSError **)aError {
    NSFileManager *tempFileManager = [self getNSFileManager];
    return [tempFileManager removeItemAtPath:aFileName error:aError];
}

#pragma mark 删除文件夹下的所有文件
+ (BOOL)deleteAllFileAtPath:(NSString *)aPath {
    BOOL result = NO;
    NSArray *fileArray = [self getContentsOfDirectoryAtPath:aPath];

    NSString *filePath = nil;

    @autoreleasepool {
        for (int i = 0; i < [fileArray count]; i++) {
            filePath = [aPath stringByAppendingPathComponent:[fileArray objectAtIndex:i]];
            result = [[self getNSFileManager] removeItemAtPath:filePath error:nil];
            if (!result) {
                break;
            }
            filePath = nil;
        }
        return result;
    }
}
+ (BOOL)deleteDirAtPath:(NSString *)filePath {
    BOOL result = [[self getNSFileManager] removeItemAtPath:filePath error:nil];
    return result;
}
#pragma mark 根据文件名删除document下的文件
+ (BOOL)deleteFileAtDocumentsWithName:(NSString *)aFilename error:(NSError **)aError {
    NSString *filePath = [self getFullPathWithName:aFilename];
    return [self deleteFileWithName:filePath error:aError];
}

#pragma mark 获取tmp路径
+ (NSString *)getTmpPath {
    NSString *pathName = [NSHomeDirectory() stringByAppendingPathComponent:@"tmp"];
    return pathName;
}

#pragma mark 获取caches路径
+ (NSString *)getCachesPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

#pragma mark 在Document下创建文件目录
+ (BOOL)createDirectoryAtDocument:(NSString *)aDirectory {
    NSFileManager *tempFileManager = [self getNSFileManager];
    NSString *directoryAll = [self getFullPathWithName:aDirectory];

    BOOL result =
        [tempFileManager createDirectoryAtPath:directoryAll withIntermediateDirectories:YES attributes:nil error:nil];
    return result;
}
+ (BOOL)createDirectoryAtPath:(NSString *)path {
    NSFileManager *fileManage = [self getNSFileManager];
    BOOL isDir = YES;
    if ([fileManage fileExistsAtPath:path isDirectory:&isDir]) {
        [fileManage removeItemAtPath:path error:nil];
    }
    BOOL suc = [fileManage createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    return suc;
}
#pragma mark 读取文件
+ (NSData *)readFileWithPath:(NSString *)aPath {
    NSData *data = [NSData dataWithContentsOfFile:aPath];
    return data;
}

#pragma mark 遍历文件夹下的所有文件,不含子文件
+ (NSArray *)getContentsOfDirectoryAtPath:(NSString *)aDireString {
    NSFileManager *tempFileManager = [self getNSFileManager];
    return [tempFileManager contentsOfDirectoryAtPath:aDireString error:nil];
}

#pragma mark 遍历文件夹下的所有文件,含子文件
+ (NSArray *)getAllFilesAtPath:(NSString *)aDirString {
    NSMutableArray *temPathArray = [NSMutableArray array];

    NSFileManager *tempFileManager = [self getNSFileManager];
    NSArray *tempArray = [self getContentsOfDirectoryAtPath:aDirString];
    NSString *fullPath = nil;

    @autoreleasepool {
        for (NSString *fileName in tempArray) {
            BOOL flag = YES;
            fullPath = [aDirString stringByAppendingPathComponent:fileName];

            //判断是否存在
            if ([tempFileManager fileExistsAtPath:fullPath isDirectory:&flag]) {
                //不是目录，直接添加
                if (!flag) {
                    // ignore .DS_Store
                    if (![[fileName substringToIndex:1] isEqualToString:@"."]) {
                        [temPathArray addObject:fullPath];
                    }
                }
                //如果是目录的话，以当前文件夹为key,文件夹下的子文件名为value,递归调用
                else {
                    NSArray *subPathArray = [self getAllFilesAtPath:fullPath];
                    NSDictionary *subPathDic =
                        [[NSDictionary alloc] initWithObjectsAndKeys:subPathArray, fullPath, nil];
                    [temPathArray addObject:subPathDic];
                }
            }
            fullPath = nil;
        }
    }
    NSArray *resultArray = [NSArray arrayWithArray:temPathArray];

    return resultArray;
}

+ (NSArray *)getAllFilesURLAtPath:(NSString *)aDirString {
    NSMutableArray *temPathArray = [NSMutableArray array];

    NSFileManager *tempFileManager = [self getNSFileManager];
    NSArray *tempArray = [self getContentsOfDirectoryAtPath:aDirString];
    NSString *fullPath = nil;

    @autoreleasepool {
        for (NSString *fileName in tempArray) {
            BOOL flag = YES;
            fullPath = [aDirString stringByAppendingPathComponent:fileName];

            //判断是否存在
            if ([tempFileManager fileExistsAtPath:fullPath isDirectory:&flag]) {
                //不是目录，直接添加
                if (!flag) {
                    // ignore .DS_Store
                    if (![[fileName substringToIndex:1] isEqualToString:@"."]) {
                        [temPathArray addObject:[NSURL fileURLWithPath:fullPath]];
                    }
                }
                //如果是目录的话，以当前文件夹为key,文件夹下的子文件名为value,递归调用
                else {
                    NSArray *subPathArray = [self getAllFilesURLAtPath:fullPath];

                    [temPathArray addObjectsFromArray:subPathArray];
                }
            }
            fullPath = nil;
        }
    }
    NSArray *resultArray = [NSArray arrayWithArray:temPathArray];

    return resultArray;
}

#pragma mark 复制一个目录下的文件到另外一个目录,前后两个必须一致，要么都是目录，要么都是文件
+ (BOOL)copyItemAtPath:(NSString *)aPath toPath:(NSString *)aDestinationPath error:(NSError **)aError {
    NSFileManager *tempFileManager = [self getNSFileManager];
    return [tempFileManager copyItemAtPath:aPath toPath:aDestinationPath error:aError];
}

#pragma mark 重命名文件
+ (BOOL)renameFileNameFrom:(NSString *)aOldName toPath:(NSString *)aNewName error:(NSError **)aError {
    NSFileManager *tempFileManager = [self getNSFileManager];
    BOOL result = [tempFileManager moveItemAtPath:aOldName toPath:aNewName error:aError];
    return result;
}

+ (UInt32)fileEncoding:(NSString *)path {
    do {
#define NUMBER_OF_SAMPLES (2048)
        FILE *file;
        char buffer[NUMBER_OF_SAMPLES];
        size_t len;
        uchardet_t ud;

        /* 打开被检测文本文件，并读取一定数量的样本字符 */
        file = fopen([path UTF8String], "rt");
        if (file == NULL)
            break;

        len = fread(buffer, sizeof(char), NUMBER_OF_SAMPLES, file);

        fclose(file);

        ud = uchardet_new();
        if (uchardet_handle_data(ud, buffer, len) != 0)
            break;
        uchardet_data_end(ud);
        return [self matchEncode:ud];
    } while (0);
    return 0;
}
+ (UInt32)fileEncodingOfChar:(const char *)data {
#define NUMBER_OF_DATA_LEN (256)
    size_t len = strlen(data);
    if (len <= 0 || !data) {
        return 0;
    }
    int max = NUMBER_OF_DATA_LEN;
    char buffer[NUMBER_OF_DATA_LEN];

    size_t lenall = 0;
    char *datatemp = buffer;

    while ((datatemp - buffer) < (max - len)) {
        strncpy(datatemp, data, len);
        datatemp += len;
        lenall += len;
    }
    uchardet_t ud;
    ud = uchardet_new();

    if (uchardet_handle_data(ud, buffer, lenall) != 0)
        return 0;
    uchardet_data_end(ud);
    return [self matchEncode:ud];
}

+ (UInt32)matchEncode:(uchardet_t)ud {
    const char *encode = uchardet_get_charset(ud);

#define MAP(string, cfencode)              \
    if (strcasecmp(encode, string) == 0) { \
        uchardet_delete(ud);               \
        return cfencode;                   \
    }
    MAP("GB18030", kCFStringEncodingGB_18030_2000)
    MAP("GB2312", kCFStringEncodingGB_2312_80)
    MAP("x-euc-tw", kCFStringEncodingEUC_TW)
    MAP("EUC-KR", kCFStringEncodingEUC_KR)
    MAP("EUC-JP", kCFStringEncodingEUC_JP)
    MAP("ISO-2022-JP", kCFStringEncodingISO_2022_JP)
    MAP("ISO-8859-2", kCFStringEncodingISOLatin2)
    MAP("UTF-8", kCFStringEncodingUTF8)
    MAP("UTF8", kCFStringEncodingUTF8)
    MAP("windows-1250", kCFStringEncodingWindowsLatin2)
    MAP("windows-1251", kCFStringEncodingWindowsCyrillic)
    MAP("windows-1252", kCFStringEncodingWindowsLatin1)
    MAP("windows-1253", kCFStringEncodingWindowsGreek)
    MAP("Big5", kCFStringEncodingBig5)
    MAP("EUC-KR", kCFStringEncodingEUC_KR)
    MAP("EUCKR", kCFStringEncodingEUC_KR)
    MAP("x-euc-tw", kCFStringEncodingEUC_TW)
    MAP("EUCTW", kCFStringEncodingEUC_TW)
    MAP("HZ-GB-2312", kCFStringEncodingHZ_GB_2312)
    MAP("x-mac-cyrillic", kCFStringEncodingMacCyrillic)
    MAP("KOI8-R", kCFStringEncodingKOI8_R)
    MAP("ISO-2022-CN", kCFStringEncodingISO_2022_CN)
    MAP("ISO-2022-KR", kCFStringEncodingISO_2022_KR)
    MAP("ISO-8859-5", kCFStringEncodingISOLatinCyrillic)
    MAP("ISO-8859-7", kCFStringEncodingISOLatinGreek)
    MAP("ISO-8859-8", kCFStringEncodingISOLatinHebrew)
    MAP("ISO-8859-8-I", kCFStringEncodingISOLatinHebrew)
    MAP("TIS-620", kCFStringEncodingDOSThai)
    MAP("windows-1255", kCFStringEncodingWindowsHebrew)
    MAP("x-mac-hebrew", kCFStringEncodingMacHebrew)
    MAP("Shift_JIS", kCFStringEncodingShiftJIS)
    MAP("SJIS", kCFStringEncodingShiftJIS)
    MAP("IBM855", kCFStringEncodingDOSCyrillic)
    MAP("IBM866", kCFStringEncodingDOSRussian)
    MAP("UTF-16BE", kCFStringEncodingUTF16BE)
    MAP("UTF-16LE", kCFStringEncodingUTF16LE)
    MAP("UTF-32BE", kCFStringEncodingUTF32BE)
    MAP("UTF-32LE", kCFStringEncodingUTF32LE)
    MAP("X-ISO-10646-UCS-4-2143", kCFStringEncodingUTF32)
    MAP("X-ISO-10646-UCS-4-3412", kCFStringEncodingUTF32)
    return 0;
}
@end
