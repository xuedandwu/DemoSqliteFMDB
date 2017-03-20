//
//  ViewController.m
//  DemoSqlite
//
//  Created by zhengtaixiang on 16/10/8.
//  Copyright © 2016年 zhengtaixiang. All rights reserved.
//

#import "ViewController.h"
#import <sqlite3.h>
#import "FMDB.h"

#define KDBName @"DemoDB.sqlite"//数据库(也可以是.db)
#define KFMDBName @"TESTFMDB.sqlite"//数据库(也可以是.db)
#define KTBUserInfo @"userInfo"//用户信息表
#define KTBDog @"dogInfo"//dog信息表
#define documents [NSHomeDirectory() stringByAppendingString:@"/Documents"]

@interface ViewController (){
    sqlite3 *db;
    FMDatabase *fmdb;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
//    [self mySqliteTest];//原生sqlite
    
    [self fmdbTest];//FMDB
}
#pragma mark ---------FMDB-----------
- (void)fmdbTest{
    [self fmdbCreate];
    [self fmdbTableCreate];
    [self fmdbInsertData];
    [self fmdbUpdateData];
    [self fmdbDeleteData];
    [self fmdbSelectData];
    [self fmdbQueue];
}
#pragma amrk - fmdb创建数据库
- (void)fmdbCreate{
    NSString *database_path = [documents stringByAppendingPathComponent:KFMDBName];
    //数据库打开、创建
    fmdb = [FMDatabase databaseWithPath:database_path];
}
#pragma amrk - fmdb创建表
- (void)fmdbTableCreate{
    NSString *sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (ID INTEGER PRIMARY KEY AUTOINCREMENT, name VARCHAR, age INTEGER, sex INTEGER, phoneNum VARCHAR);",KTBUserInfo];
    [self fmdbExecSql:sql];
}
#pragma mark - fmdbUpdate
- (void)fmdbExecSql:(NSString *)sql{
    if ([fmdb open]) {
        
        /*
         * 只要sql不是SELECT命令的都视为更新操作(使用executeUpdate方法)。就包括 CREAT,UPDATE,INSERT,ALTER,BEGIN,COMMIT,DETACH,DELETE,DROP,END,EXPLAIN,VACUUM,REPLACE等等。SELECT命令的话，使用executeQuery方法。
         * 执行更新返回一个BOOL值。YES表示 执行成功，否则表示有错误。你可以调用 -lastErrorMessage 和 -lastErrorCode方法来得到更多信息。
         */
        if ([fmdb executeUpdate:sql]) {
            NSLog(@"%@%@%@",@"fmdb操作表",KTBUserInfo,@"成功！");
        }else{
            NSLog(@"%@%@%@ lastErrorMessage：%@，lastErrorCode：%d",@"fmdb创建",KTBUserInfo,@"失败！",fmdb.lastErrorMessage,fmdb.lastErrorCode);
        }
    }else{
        NSLog(@"%@",@"fmdb数据库打开失败！");
    }
}
#pragma mark - fmdb插入数据
- (void)fmdbInsertData{
    NSString *sql = [NSString stringWithFormat:
                     @"INSERT INTO '%@' ('name', 'age', 'sex', 'phoneNum') VALUES ('%@', '%@', '%@','%@');",KTBUserInfo, @"张三", @"23", @"1",@"18875022022"];
    [self fmdbExecSql:sql];
    
    sql = [NSString stringWithFormat:
           @"INSERT INTO '%@' ('name', 'age', 'sex', 'phoneNum') VALUES ('%@', '%@', '%@','%@');",KTBUserInfo, @"李四", @"24", @"0",@"18875022023"];
    [self fmdbExecSql:sql];
    
    sql = [NSString stringWithFormat:
           @"INSERT INTO '%@' ('name', 'age', 'sex', 'phoneNum') VALUES ('%@', '%@', '%@','%@');",KTBUserInfo, @"王五", @"25", @"1",@"18875022024"];
    [self fmdbExecSql:sql];
}
#pragma mark - fmdb修改数据
- (void)fmdbUpdateData{
    NSString *sql = [NSString stringWithFormat:@"UPDATE %@ set age='%@' WHERE name='张三';",KTBUserInfo,@"2333"];
    [self fmdbExecSql:sql];
}
#pragma mark - fmdb删除数据
- (void)fmdbDeleteData{
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE name='张三';",KTBUserInfo];
    [self fmdbExecSql:sql];
}
#pragma mark - fmdbSelectData
- (void)fmdbSelectData{
    NSString *sqlQuery = [NSString stringWithFormat:@"SELECT * FROM %@;",KTBUserInfo];
    
    //根据条件查询
    FMResultSet *resultSet = [fmdb executeQuery:sqlQuery];
    
    //遍历结果集合
    while ([resultSet  next]){
        NSString *name = [resultSet
                          objectForColumnName:@"name"];
        int age = [resultSet intForColumn:@"age"];
        int sex = [resultSet intForColumn:@"sex"];
        NSString *phone = [resultSet objectForColumnName:@"phoneNum"];
            
        NSLog(@"%@: name:%@ age:%d sex:%d phoneNum:%@",KTBUserInfo,name,age,sex,phone);
    }
    /*
     * fmdb封装过后的读取数据是要比原生的sqlite3方便了很多哈
     */
}
#pragma mark - fmdb多线程
- (void)fmdbQueue{
    //创建队列
    FMDatabaseQueue *queue = [FMDatabaseQueue
                              databaseQueueWithPath:[documents stringByAppendingPathComponent:KFMDBName]];
    __block BOOL tag = true;
    
    //把任务放到到队列里
    [queue inTransaction:^(FMDatabase *dbe, BOOL *rollback)
     {
         tag &= [dbe executeUpdate:@"INSERT INTO userInfo ('age') VALUES (?)",[NSNumber numberWithInt:11]];
         tag &= [dbe executeUpdate:@"INSERT INTO userInfo ('age') VALUES (?)",[NSNumber numberWithInt:22]];
         tag &= [dbe executeUpdate:@"INSERT INTO userInfo ('age') VALUES (?)",[NSNumber numberWithInt:33]];
         //如果有错误 返回
         if (!tag)
         { 
             *rollback = YES;
             return;
         }
     }];
}

#pragma mark --------------------
#pragma mark - sqlite数据库
- (void)mySqliteTest{
    [self createDataBase];
    [self createTable];
    
    [self insertData];
    NSLog(@"第一次插入数据后查询表dogInfo===========================");
    [self queryDataWithTableName:KTBDog];
    NSLog(@"第一次插入数据后查询表userInfo===========================");
    [self queryDataWithTableName:KTBUserInfo];
    
    [self insertData];
    NSLog(@"第二次插入数据后查询表dogInfo===========================");
    [self queryDataWithTableName:KTBDog];
    NSLog(@"第二次插入数据后查询表userInfo===========================");
    [self queryDataWithTableName:KTBUserInfo];
    
    //修改（不严谨的修改，通常修改和删除操作where条件是id关联）
    NSString *sql = [NSString stringWithFormat:@"UPDATE %@ set age='%@' WHERE name='张三';",KTBUserInfo,@"2333"];
    [self updateDataWithSql:sql];
    NSLog(@"修改表userInfo的数据后查询===========================");
    [self queryDataWithTableName:KTBUserInfo];
    
    //删除
    sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE name='张三';",KTBUserInfo];
    [self deleteDataWithSql:sql];
    NSLog(@"删除表userInfo的数据后查询===========================");
    [self queryDataWithTableName:KTBUserInfo];
    
    //关闭数据库
    sqlite3_close(db);
    /*
     * 数据库如果长期打开不关闭，会一直占用着内存。所以最好是用的时候开sqlite3_open，不用了就关sqlite3_close。
     * 我这里没有用一次就关闭，毕竟一个小demo，但也按照随用随关做了，只是注释了。
     */
}
#pragma mark ---------mySqliteTest-----------
#pragma mark - 创建数据库并打开
- (void)createDataBase{

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsStr = [paths objectAtIndex:0];
    //应用的文档目录
    NSLog(@"%@",documentsStr);
    
    NSString *database_path = [documentsStr stringByAppendingPathComponent:KDBName];
    //打开数据库，如果没有的话，就会在该目录创建该数据库。
    if(sqlite3_open([database_path UTF8String], &db) != SQLITE_OK) {
        sqlite3_close(db);
    }
}
#pragma mark - 创建表
- (void)createTable{
    //IF NOT EXISTS 如果不存在 （如果该数据库已经存在了该表，则sqlite3_exec在执行数据库操作的时候不会报错给我们，如果表已经存在了，又没有加这个判断的话，会执行不成功并关闭数据库）
    NSString *sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (ID INTEGER PRIMARY KEY AUTOINCREMENT, name VARCHAR, age INTEGER, sex INTEGER, phoneNum VARCHAR);",KTBUserInfo];
    [self execSql:sql];
    
    sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (ID INTEGER PRIMARY KEY AUTOINCREMENT, name VARCHAR, age integer, sex INTEGER);",KTBDog];
    [self execSql:sql];
    
    /*
     * sqlite数据库里面的数据类型参考SQLite数据库的文档，这里的sql语句CREATE、INTEGER等关键词，大写是为了区分这是系统的，并不是规定的，小写也是能正常通过的，不过，为了规范，建议大写。
     */
}
#pragma mark - 插入数据
- (void)insertData{
    NSString *sql = [NSString stringWithFormat:
                      @"INSERT INTO '%@' ('name', 'age', 'sex', 'phoneNum') VALUES ('%@', '%@', '%@','%@');",KTBUserInfo, @"张三", @"23", @"1",@"18875022022"];
    [self execSql:sql];
    
    sql = [NSString stringWithFormat:
           @"INSERT INTO '%@' ('name', 'age', 'sex', 'phoneNum') VALUES ('%@', '%@', '%@','%@');",KTBUserInfo, @"李四", @"24", @"0",@"18875022023"];
    [self execSql:sql];
    
    sql = [NSString stringWithFormat:
           @"INSERT INTO '%@' ('name', 'age', 'sex', 'phoneNum') VALUES ('%@', '%@', '%@','%@');",KTBUserInfo, @"王五", @"25", @"1",@"18875022024"];
    [self execSql:sql];
    
    sql = [NSString stringWithFormat:
                      @"INSERT INTO '%@' ('name', 'age', 'sex') VALUES ('%@', '%@', '%@');",KTBDog, @"小黑", @"1", @"1"];
    [self execSql:sql];
    
    sql = [NSString stringWithFormat:
           @"INSERT INTO '%@' ('name', 'age', 'sex') VALUES ('%@', '%@', '%@');",KTBDog, @"小白", @"1", @"0"];
    [self execSql:sql];
    
}
#pragma mark - 修改数据
- (void)updateDataWithSql:(NSString *)sql{
    [self execSql:sql];
}
#pragma mark - 删除数据
- (void)deleteDataWithSql:(NSString *)sql{
    [self execSql:sql];
}
#pragma mark - 查询数据(默认查询全部)
- (void)queryDataWithTableName:(NSString *)tbName{
//    sqlite3_open([[documents stringByAppendingPathComponent:KDBName] UTF8String], &db);
    NSString *sqlQuery = [NSString stringWithFormat:@"SELECT * FROM %@;",tbName];
    sqlite3_stmt *statement;
    if (sqlite3_prepare_v2(db, [sqlQuery UTF8String], -1, &statement, nil) == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            
            char *name = (char*)sqlite3_column_text(statement, 1);
            NSString *nsNameStr = [[NSString alloc] initWithUTF8String:name];
            
            int age = sqlite3_column_int(statement, 2);
            int sex = sqlite3_column_int(statement, 3);
            
            int columnCount = sqlite3_column_count(statement);
            if (columnCount == 5) {//为了兼容我这里两个表，其中一个表少一个字段，拣个懒
                char *phoneNum = (char*)sqlite3_column_text(statement, 4);
                NSString *phoneNumStr = [[NSString alloc] initWithUTF8String:phoneNum];
                
                NSLog(@"%@: name:%@ age:%d sex:%d phoneNum:%@",tbName,nsNameStr,age,sex,phoneNumStr);
            }else{
                NSLog(@"%@: name:%@ age:%d sex:%d",tbName,nsNameStr,age,sex);
            }
        }
    }else{
        NSLog(@"%@查询数据失败",tbName);
    }
//    sqlite3_close(db);
}
#pragma mark - 执行sql
- (void)execSql:(NSString *)sql{
    char *err;
//    sqlite3_open([[documents stringByAppendingPathComponent:KDBName] UTF8String], &db);
    sqlite3_exec(db, [sql UTF8String], NULL, NULL, &err);
//    sqlite3_close(db);
}
#pragma mark --------------------
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)dealloc{
    sqlite3_close(db);
}

@end
