//
//  LE_DataManager.m
//  ticket
//
//  Created by emerson larry on 15/12/2.
//  Copyright © 2015年 360cbs. All rights reserved.
//

#import "LE_DataManager.h"

@implementation LE_DataManager {
    FMDatabase *db;
    BOOL enableDebug;
}
static LE_DataManager *_instance;
static LE_DataManager *_instanceCache;
static LE_DataManager *_instanceStorage;
+ (LE_DataManager *) sharedInstance{ return _instance;}
+ (LE_DataManager *) sharedInstanceOfCache { @synchronized(self) { if (!_instanceCache) { _instanceCache = [[LE_DataManager alloc] initForCache]; } return _instanceCache; } }
+ (LE_DataManager *) sharedInstanceOfStorage { @synchronized(self) { if (!_instanceStorage) { _instanceStorage = [[LE_DataManager alloc] initForStorage]; } return _instanceStorage; } }
//
-(id)initForCache{ return [self initForCacheWithName:@"ApplicationCache.db"]; }
-(id)initForStorage{ return [self initForStorageWithName:@"ApplicationData.db"]; }
-(id)initForCacheWithName:(NSString *) cache{ return _instanceCache=[self initWithPath:[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] Name:cache]; }
-(id)initForStorageWithName:(NSString *) storage{ return _instanceStorage=[self initWithPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] Name:storage]; }
-(id)initWithPath:(NSString *) path Name:(NSString *) name{
    NSString *filePath=nil;
    if(path&&name){
        filePath=[NSString stringWithFormat:@"%@/%@",path,name];
    }
    if(filePath){
        db = [FMDatabase databaseWithPath:filePath];
        if([db open]){
            return _instance=self=[super init];
        }
    }
    return nil;
}
//
- (void) leSetEnableDebug:(BOOL) enable{
    enableDebug=enable;
}
-(void) leCreateTableIfNotExists:(NSString *) table{
    [self leExecute:[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS \"%@\" (\n\"key\" Text NOT NULL PRIMARY KEY,\n\"value\" Text NOT NULL )",table]];
}

-(NSString *) leGetDataWithTable:(NSString *) table Key:(NSString *) key{
    [self leCreateTableIfNotExists:table];
    return [self leScalar:[NSString stringWithFormat:@"select value from %@ where key=\'%@\'",table,key]];
}
-(void) leAddOrUpdateWithKey:(NSString *) key Value:(NSString *) value ToTable:(NSString *) table{
    [self leCreateTableIfNotExists:table];
    [self leDeleteRecordWithKey:key FromTable:table];
    [self leExecute:[NSString stringWithFormat:@"insert into %@ (key,value) values ('%@', '%@')",table,key,value]];
}
-(void) leAddKey:(NSString *) key Value:(NSString *) value ToTable:(NSString *) table{
    [self leCreateTableIfNotExists:table];
    [self leExecute:[NSString stringWithFormat:@"insert into %@ (key,value) values ('%@', '%@')",table,key,value]];
}
-(NSMutableArray *) leGetDataWithTable:(NSString *)table{
    [self leCreateTableIfNotExists:table];
    return [self leQuery:[NSString stringWithFormat:@"select * from %@",table]];
}
-(void) leClearTable:(NSString *) table{
    [self leExecute:[NSString stringWithFormat:@"delete from %@",table]];
}
-(void) leDeleteRecordWithKey:(NSString *) key FromTable:(NSString *) table{
    [self leExecute:[NSString stringWithFormat:@"delete from %@ where key='%@'",table,key]];
}
-(void) leClearAllCache{
    [self leExecute:@"vacuum"];
}
//
- (void)dealloc {
    [db close];
}
- (NSMutableArray *)leQuery:(NSString *)sql {
    if(enableDebug){
        NSLog(@"\nsql: %@\n\n", sql);
    }
    NSMutableArray *result = [[NSMutableArray alloc] init];
    FMResultSet *rs = [db executeQuery:sql];
    while([rs next]) {
        [result addObject:[rs resultDictionary]];
    }
    [rs close];
    return result;
}

- (NSDictionary *)leFetch:(NSString *)sql {
    if(enableDebug){
        NSLog(@"\nsql: %@\n\n", sql);
    }
    FMResultSet *rs = [db executeQuery:sql];
    NSDictionary *result = nil;
    if ([rs next]) {
        result = [rs resultDictionary];
    }
    [rs close];
    return result;
}

- (id)leScalar:(NSString *)sql {
    if(enableDebug){
        NSLog(@"\nsql: %@\n\n", sql);
    }
    FMResultSet *rs = [db executeQuery:sql];
    id result;
    if ([rs next]) {
        result = [rs objectForColumnIndex:0];
    } else {
        result = nil;
    }
    [rs close];
    return result;
}

- (BOOL)leExecute:(NSString *)sql {
    if(enableDebug){
        NSLog(@"\nsql: %@\n\n", sql);
    }
    return [db executeUpdate:sql];
}

- (long long int)leInsert:(NSString *)sql {
    if(enableDebug){
        NSLog(@"\nsql: %@\n\n", sql);
    }
    [db executeUpdate:sql];
    return db.lastInsertRowId;
}

- (void)leBeginTransaction {
    [db beginTransaction];
}

- (void)leCommit {
    [db commit];
}

- (void)leInitTable:(NSString *)tableName withData:(NSMutableArray *)data {
    [self leBeginTransaction];
    [self leExecute:[NSString stringWithFormat:@"delete from %@",tableName]];
    for (NSMutableDictionary *row in data) {
        NSString *fields = [[NSString alloc] init];
        NSString *values = [[NSString alloc] init];
        for (NSString *key in [row allKeys]) {
            fields = [fields stringByAppendingFormat:@"%@,",key];
            values = [values stringByAppendingFormat:@"'%@',",[row objectForKey:key]];
        }
        fields = [fields substringToIndex:[fields length]-1];
        values = [values substringToIndex:[values length]-1];
        NSString *sql = [NSString stringWithFormat:@"insert into %@(%@) values(%@)",tableName,fields,values];
        [self leExecute:sql];
    }
    [self leCommit];
}

-(void) leBatchImportable:(NSString *) tableName WithData:(NSMutableArray *) data {
    [self leBeginTransaction];
    [self leExecute:[NSString stringWithFormat:@"delete from %@",tableName]];
    for (int i=0; i<data.count; i++) {
        [self leExecute:[data objectAtIndex:i]];
    }
    [self leCommit];
}
@end