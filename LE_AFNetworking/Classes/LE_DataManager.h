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

#define DataManagerDebug 0
 

@interface LE_DataManager : NSObject
+ (LE_DataManager *) instance;
+ (LE_DataManager *) instanceOfCache;
+ (LE_DataManager *) instanceOfStorage;
-(id)initForCacheWithName:(NSString *) cache;
-(id)initForStorageWithName:(NSString *) storage;
-(id)initWithPath:(NSString *) path Name:(NSString *) name;
//
-(void) createTableIfNotExists:(NSString *) table;
-(NSString *) getDataWithTable:(NSString *) table Key:(NSString *) key;
-(void) addOrUpdateWithKey:(NSString *) key Value:(NSString *) value ToTable:(NSString *) table;
-(void) addKey:(NSString *) key Value:(NSString *) value ToTable:(NSString *) table;
-(NSMutableArray *) getDataWithTable:(NSString *)table;
-(void) clearTable:(NSString *) table;
-(void) deleteRecordWithKey:(NSString *) key FromTable:(NSString *) table;
-(void) clearAllCache;
//
- (NSMutableArray *) query:(NSString *)sql;
- (NSDictionary *) fetch:(NSString *)sql;
- (id) scalar:(NSString *)sql;
- (BOOL) execute:(NSString *)sql;
- (long long int)insert:(NSString *)sql;
- (void) beginTransaction;
- (void) commit;
- (void) initTable:(NSString *)tableName withData:(NSMutableArray *)data;
- (void) batchImportable:(NSString *) tableName WithData:(NSMutableArray *) data ;
@end 