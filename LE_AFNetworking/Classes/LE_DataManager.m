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
}
static LE_DataManager *_instance;
static LE_DataManager *_instanceCache;
static LE_DataManager *_instanceStorage;
+ (LE_DataManager *) instance{ return _instance;}
+ (LE_DataManager *) instanceOfCache { @synchronized(self) { if (!_instanceCache) { _instanceCache = [[LE_DataManager alloc] initForCache]; } return _instanceCache; } }
+ (LE_DataManager *) instanceOfStorage { @synchronized(self) { if (!_instanceStorage) { _instanceStorage = [[LE_DataManager alloc] initForStorage]; } return _instanceStorage; } }
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
-(void) createTableIfNotExists:(NSString *) table{
    [self execute:[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS \"%@\" (\n\"key\" Text NOT NULL PRIMARY KEY,\n\"value\" Text NOT NULL )",table]];
}

-(NSString *) getDataWithTable:(NSString *) table Key:(NSString *) key{
    [self createTableIfNotExists:table];
    return [self scalar:[NSString stringWithFormat:@"select value from %@ where key=\'%@\'",table,key]];
}
-(void) addOrUpdateWithKey:(NSString *) key Value:(NSString *) value ToTable:(NSString *) table{
    [self createTableIfNotExists:table];
    [self deleteRecordWithKey:key FromTable:table];
    [self execute:[NSString stringWithFormat:@"insert into %@ (key,value) values ('%@', '%@')",table,key,value]];
}
-(void) addKey:(NSString *) key Value:(NSString *) value ToTable:(NSString *) table{
    [self createTableIfNotExists:table];
    [self execute:[NSString stringWithFormat:@"insert into %@ (key,value) values ('%@', '%@')",table,key,value]];
}
-(NSMutableArray *) getDataWithTable:(NSString *)table{
    [self createTableIfNotExists:table];
    return [self query:[NSString stringWithFormat:@"select * from %@",table]];
}
-(void) clearTable:(NSString *) table{
    [self execute:[NSString stringWithFormat:@"delete from %@",table]];
}
-(void) deleteRecordWithKey:(NSString *) key FromTable:(NSString *) table{
    [self execute:[NSString stringWithFormat:@"delete from %@ where key='%@'",table,key]];
}
-(void) clearAllCache{
    [self execute:@"vacuum"];
}
//
- (void)dealloc {
    [db close];
}
- (NSMutableArray *)query:(NSString *)sql {
#if DataManagerDebug
    NSLog(@"\nsql: %@\n\n", sql);
#endif
    NSMutableArray *result = [[NSMutableArray alloc] init];
    FMResultSet *rs = [db executeQuery:sql];
    while([rs next]) {
        [result addObject:[rs resultDictionary]];
    }
    [rs close];
    return result;
}

- (NSDictionary *)fetch:(NSString *)sql {
#if DataManagerDebug
    NSLog(@"\nsql: %@\n\n", sql);
#endif
    FMResultSet *rs = [db executeQuery:sql];
    NSDictionary *result = nil;
    if ([rs next]) {
        result = [rs resultDictionary];
    }
    [rs close];
    return result;
}

- (id)scalar:(NSString *)sql {
#if DataManagerDebug
    NSLog(@"\nsql: %@\n\n", sql);
#endif
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

- (BOOL)execute:(NSString *)sql {
#if DataManagerDebug
    NSLog(@"\nsql: %@\n\n", sql);
#endif
    return [db executeUpdate:sql];
}

- (long long int)insert:(NSString *)sql {
#if DataManagerDebug
    NSLog(@"\nsql: %@\n\n", sql);
#endif
    [db executeUpdate:sql];
    return db.lastInsertRowId;
}

- (void)beginTransaction {
    [db beginTransaction];
}

- (void)commit {
    [db commit];
}

- (void)initTable:(NSString *)tableName withData:(NSMutableArray *)data {
    [self beginTransaction];
    [self execute:[NSString stringWithFormat:@"delete from %@",tableName]];
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
        [self execute:sql];
    }
    [self commit];
}

-(void) batchImportable:(NSString *) tableName WithData:(NSMutableArray *) data {
    [self beginTransaction];
    [self execute:[NSString stringWithFormat:@"delete from %@",tableName]];
    for (int i=0; i<data.count; i++) {
        [self execute:[data objectAtIndex:i]];
    }
    [self commit];
}
@end