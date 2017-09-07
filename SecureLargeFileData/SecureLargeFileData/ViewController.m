//
//  ViewController.m
//  SecureLargeFileData
//
//  Created by Sachin on 17/08/17.
//  Copyright © 2017 SachinVsSachin. All rights reserved.
//

#import "ViewController.h"

#import <AVFoundation/AVFoundation.h>

#import "NSMutableArray+Shuffling.h"

NSString *const LARGE_DATA_FILE = @"HDVideo";
NSString *const LARGE_DATA_FILE_EXTENSION = @"mov";




@interface ViewController ()

@property(nonatomic,strong) NSMutableArray *slicedDataFilesInfo;

@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    NSLog(@"document directory %@",[self documentDirectory]);
    
    self.slicedDataFilesInfo = [[NSMutableArray alloc] init];
}



- (IBAction)encryptFile:(UIButton *)sender {
    
    NSUInteger offset = 0;
    
    NSString *filepath = [[NSBundle mainBundle] pathForResource:LARGE_DATA_FILE ofType:LARGE_DATA_FILE_EXTENSION];
    
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:filepath];
    
    unsigned long long totolSize = [handle seekToEndOfFile];
    
    NSUInteger chunkSize = 0;
    
    chunkSize = (NSUInteger)totolSize/10;
    
    [handle seekToFileOffset:0];
    
    NSData *data = [handle readDataOfLength:chunkSize];
    
    /* Check for data validation */
    BOOL isDataAvailable = totolSize>0?YES:NO;
    
    while (isDataAvailable)
    {
        
        @autoreleasepool{
            
            /*
             Offset:It is use to define from where to start to read data.
             ChunkSize: How much data to read from Offset.
             */
            
            unsigned long long fileRange = offset + chunkSize;
            
            /** Check for data validation */
            if (fileRange < totolSize) {
                [handle seekToFileOffset:offset];
                data = [handle readDataOfLength:chunkSize];
                offset += [data length];
                [handle seekToFileOffset:offset];
            }else{
                data = [handle readDataToEndOfFile];
                isDataAvailable = NO;
            }
            
            NSString *file = [self fileLocation:@(offset).stringValue andExt:@"data"];
            
            /**
             Part of data which we read from a large data file, write in to file named 
             offset along with extension 'data' */
            [data writeToFile:file atomically:YES];
            
            
            NSMutableDictionary *fileInfo = [NSMutableDictionary new];
            [fileInfo setObject:[NSNumber numberWithUnsignedInteger:data.length] forKey:@"size"];
            [fileInfo setObject:file forKey:@"file"];
            [fileInfo setObject:[NSNumber numberWithUnsignedLongLong:offset] forKey:@"offset"];
            
            /** Save each chunk data information like size, offset and file path */
            [self.slicedDataFilesInfo addObject:fileInfo];
            
        }
    }
    
    [handle closeFile];
    
    [self mergeSpilittedFilesInShuffledOrder];
}



/**
 Once a large data file divided in small data files and 
 their each information eg. offset, size and file path is 
 existed in array. Next step would be to merge data parts 
 in a file with shuffled order with help of same array.
 */
- (void)mergeSpilittedFilesInShuffledOrder {
    
    NSMutableArray *slicedDataFilesInfo_copy = [self.slicedDataFilesInfo mutableCopy];
    
    [slicedDataFilesInfo_copy shuffle];
    
    /** Created a file */
    NSString *path = [self fileLocation:[NSString stringWithFormat:@"%@_encrypted_copy",LARGE_DATA_FILE] andExt:LARGE_DATA_FILE_EXTENSION];
    
    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:path];
    
    
    /** Shuffled data chunks to merge them in one file */
    [slicedDataFilesInfo_copy enumerateObjectsUsingBlock:^(NSMutableDictionary *fileInfo, NSUInteger idx, BOOL * _Nonnull stop) {
        @autoreleasepool {
            NSData *d = [NSData dataWithContentsOfFile:[fileInfo objectForKey:@"file"]];
            [fileInfo setObject:[NSNumber numberWithUnsignedLongLong:[handle offsetInFile]] forKey:@"modifiedOffset"];
            [handle writeData:d];
            [[NSFileManager defaultManager] removeItemAtPath:[fileInfo objectForKey:@"file"] error:nil];
        }
    }];
    
    [handle closeFile];
}


- (IBAction)fileDecrypt:(id)sender {
    
    NSSortDescriptor * descriptor = [[NSSortDescriptor alloc] initWithKey:@"offset" ascending:YES];
    
    NSArray *sortedArray = [self.slicedDataFilesInfo sortedArrayUsingDescriptors:@[descriptor]];
    
    NSString *encryptedFileLocation = [self fileLocation:[NSString stringWithFormat:@"%@_encrypted_copy",LARGE_DATA_FILE] andExt:LARGE_DATA_FILE_EXTENSION];
    
    NSFileHandle *readFileHandler = [NSFileHandle fileHandleForReadingAtPath:encryptedFileLocation];
    
    NSString *newFileLocation = [self fileLocation:LARGE_DATA_FILE andExt:LARGE_DATA_FILE_EXTENSION];
    
    NSFileHandle *writeFileHandler = [NSFileHandle fileHandleForWritingAtPath:newFileLocation];
    
    [sortedArray enumerateObjectsUsingBlock:^(NSDictionary *dictionary, NSUInteger idx, BOOL * _Nonnull stop) {
        unsigned long long modifiedOffset = [[dictionary objectForKey:@"modifiedOffset"] unsignedLongLongValue];
        
        NSUInteger readDataLength = [[dictionary objectForKey:@"size"] unsignedIntegerValue];
        [readFileHandler seekToFileOffset:modifiedOffset];
        NSData *data = [readFileHandler readDataOfLength:readDataLength];
        [writeFileHandler writeData:data];
    }];
    
    
    [readFileHandler closeFile];
    [writeFileHandler closeFile];
    
    [self.slicedDataFilesInfo removeAllObjects];
}





/**
 This method use to get file location inside of document folder of application

 @discussion if file is not exist, create a empty file with 
 provided file name and extension.
 @param fileName for which to get the file path
 @param ext file extension should be provided along with file name
 @return String formatted file location.
 */
- (NSString*)fileLocation:(NSString*)fileName andExt:(NSString*)ext{
    
    NSString *docsDir;
    
    NSArray *dirPaths;
    
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir = [dirPaths objectAtIndex:0];
    NSString *path = [[NSString alloc] initWithString: [docsDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@",fileName,ext]]];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    
    if ([fileManager fileExistsAtPath:path]) {
        return path;
    }
    
    [fileManager createFileAtPath:path contents:nil attributes:nil];
    
    return path;
}


/**
 Search path for document directory inside application sandbox.

 @return return String formatted docment directory path.
 */
- (NSString*)documentDirectory{
    NSString *docsDir;
    NSArray *dirPaths;
    
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir = [dirPaths objectAtIndex:0];
    return docsDir;
}






- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


/**
 
 @discussion This method is example of memory exception when try to
 load large file data in memory. Anyways this method we are 
 not using, or not called by any method or not suggest to 
 use this. To see what happens when loading large data file 
 that not fit in to memory can check it 
 
 @note Example of raising memory exception when large file 
 data not fit in to memory.
 */
- (void)largeFileDataEncryption{
    
    /*Problem statement
     
     malloc: *** mach_vm_map(size=2042146816) failed (error code=3)
     *** error: can't allocate region
     *** set a breakpoint in malloc_error_break to debug
     
     
     can't allocate region" means that there is no memory space left! Might be time to start looking into memory management and releasing unused resources.
     */
    
     NSString *filepath = [[NSBundle mainBundle] pathForResource:@"wwdc_video.mov" ofType:nil];
     
     NSData *data = [[NSFileManager defaultManager] contentsAtPath:filepath];
     
     NSString *output = [[NSString alloc]initWithData:data
     encoding:NSUTF8StringEncoding];
    
    NSLog(@"output data %@",output);
}



@end
