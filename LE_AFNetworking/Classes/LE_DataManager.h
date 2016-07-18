//
//  LE_DataManager.h
//  ticket
//
//  Created by emerson larry on 15/12/2.
//  Copyright © 2015年 360cbs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FMDatabase.h"

@interface LE_DataManager : NSObject
+ (LE_DataManager *) sharedInstance;
+ (LE_DataManager *) sharedInstanceOfCache;
+ (LE_DataManager *) sharedInstanceOfStorage;
- (id) initForCacheWithName:(NSString *) cache;
- (id) initForStorageWithName:(NSString *) storage;
- (id) initWithPath:(NSString *) path Name:(NSString *) name;
//
- (void) leSetEnableDebug:(BOOL) enable;
- (void) leCreateTableIfNotExists:(NSString *) table;
- (void) leAddOrUpdateWithKey:(NSString *) key Value:(NSString *) value ToTable:(NSString *) table;
- (void) leAddKey:(NSString *) key Value:(NSString *) value ToTable:(NSString *) table;
- (void) leClearTable:(NSString *) table;
- (void) leDeleteRecordWithKey:(NSString *) key FromTable:(NSString *) table;
- (void) leClearAllCache;
- (NSString *) leGetDataWithTable:(NSString *) table Key:(NSString *) key;
- (NSMutableArray *) leGetDataWithTable:(NSString *)table;
//
- (NSMutableArray *) leQuery:(NSString *)sql;
- (NSDictionary *) leFetch:(NSString *)sql;
- (long long int) leInsert:(NSString *)sql;
- (id)   leScalar:(NSString *)sql;
- (BOOL) leExecute:(NSString *)sql;
- (void) leBeginTransaction;
- (void) leCommit;
- (void) leInitTable:(NSString *)tableName withData:(NSMutableArray *)data;
- (void) leBatchImportable:(NSString *) tableName WithData:(NSMutableArray *) data ;
@end 