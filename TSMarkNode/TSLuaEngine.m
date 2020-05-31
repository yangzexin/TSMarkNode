//
//  TSLuaEngine.m
//  Markdown
//
//  Created by yangzexin on 2020/5/18.
//  Copyright © 2020 yangzexin. All rights reserved.
//

#import "TSLuaEngine.h"

#import <MMLuaBridge/MMLuaBridge.h>

//#import <SSZipArchive/SSZipArchive.h>

@interface TSRemoteLuaModuleSupport : NSObject <MMLuaModuleSupport>

- (id)initWithBundlePath:(NSString *)bundlePath;

@end

@interface TSRemoteLuaModuleSupport ()

@property (nonatomic, copy) NSString *bundlePath;

@end

@implementation TSRemoteLuaModuleSupport

- (id)initWithBundlePath:(NSString *)bundlePath {
    self = [super init];
    
    self.bundlePath = bundlePath;
    
    return self;
}

- (NSString *)scriptForModuleName:(NSString *)moduleName {
    NSString *fileName = [NSString stringWithFormat:@"%@.lua", moduleName];
    NSString *realFileName = [fileName sf_stringByEncryptingUsingMD5];
    
    NSData *data = [NSData dataWithContentsOfFile:[self.bundlePath stringByAppendingPathComponent:realFileName]];
    if (data.length != 0) {
        data = [data sf_dataByPerformingDESOperation:kCCDecrypt key:@"TS_DECRYPT_KEY"];
        data = [data sf_dataByExchangingByteHigh4ToLow4];
        
        NSString *script = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        return script;
    } else {
        NSString *buildinFilePath = [[NSBundle mainBundle] pathForResource:fileName ofType:nil];
        NSString *script = [NSString stringWithContentsOfFile:buildinFilePath encoding:NSUTF8StringEncoding error:nil];
        
        return script;
    }
}

@end

@interface TSLuaService : SFServant

@property (nonatomic, strong) MMLuaRunner *luaRunner;
@property (nonatomic, strong) NSString *serviceName;
@property (nonatomic, strong) NSDictionary *params;

@property (nonatomic, strong) MMLuaRunnerServiceControl *serviceControl;

@end

@implementation TSLuaService

+ (void)initialize {
}

+ (instancetype)serviceWithLuaRunner:(MMLuaRunner *)luaRunner
                         serviceName:(NSString *)serviceName
                              params:(NSDictionary *)params {
    TSLuaService *service = [TSLuaService new];
    service.luaRunner = luaRunner;
    service.serviceName = serviceName;
    service.params = params;
    
    return service;
}

- (void)servantStartingService {
    [super servantStartingService];
    
#ifdef DEBUG
    //NSLog(@"service start: %@, params: %@", self.serviceName, self.params);
#endif
    __weak typeof(self) weakSelf = self;
    self.serviceControl = [self.luaRunner requestLuaService:self.serviceName parameters:self.params completion:^(MMLuaReturn *ret) {
        __strong typeof(self) self = weakSelf;
#ifdef DEBUG
        //NSLog(@"service finish: %@, result: %@", self.serviceName, ret.value);
#endif
        if (ret.value) {
            [self returnWithFeedback:[SFServantFeedback feedbackWithValue:ret.value]];
        } else {
            [self returnWithFeedback:[SFServantFeedback feedbackWithError:[NSError errorWithDomain:NSStringFromClass([self class]) code:-1 userInfo:@{NSLocalizedDescriptionKey : ret.error}]]];
        }
    }];
}

- (void)cancel {
    [super cancel];
    [self.serviceControl cancel];
}

@end

@interface TSEngineManager : NSObject

+ (instancetype)shared;

- (void)addEngine:(TSLuaEngine *)luaEngine;

- (TSLuaEngine *)luaEngineWithId:(NSUInteger)engineId;

- (void)removeEngine:(NSUInteger)luaEngine;

@end

@interface TSEngineManager ()

@property (nonatomic, strong) NSMutableArray *engines;

@end

@implementation TSEngineManager

+ (instancetype)shared {
    static TSEngineManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [TSEngineManager new];
    });
    
    return instance;
}

- (id)init {
    self = [super init];
    
    self.engines = [NSMutableArray array];
    
    return self;
}

- (void)addEngine:(TSLuaEngine *)luaEngine {
    [self. engines addObject:[NSValue sf_valueWithWeakObject:luaEngine]];
}

- (TSLuaEngine *)luaEngineWithId:(NSUInteger)engineId {
    NSValue *target = [self _engineByFindingWithId:engineId];
    TSLuaEngine *engine = [target sf_weakObject];
    
    return engine;
}

- (NSValue *)_engineByFindingWithId:(NSUInteger)engineId {
    NSValue *target = nil;
    
    for (NSValue *value in self.engines) {
        TSLuaEngine *tmp = [value sf_weakObject];
        if (tmp.engineId == engineId) {
            target = value;
            break;
        }
    }
    
    return target;
}

- (void)removeEngine:(NSUInteger)engindId {
    NSValue *target = [self _engineByFindingWithId:engindId];
    if (target) {
        [self.engines removeObject:target];
    }
}


@end

@interface TSLuaEngine ()

@property (nonatomic, strong) MMLuaRunner *luaRunner;

@end

@implementation TSLuaEngine

+ (instancetype)engineFromMainBundle {
    TSLuaEngine *engine = [TSLuaEngine new];
    
    return engine;
}

- (void)dealloc {
    if (self.luaRunner) {
        [[TSEngineManager shared] removeEngine:self.engineId];
    }
}

- (id)init {
    self = [super init];
    
    return self;
}

+ (instancetype)engineByFindingWithId:(NSUInteger)engineId {
    return [[TSEngineManager shared] luaEngineWithId:engineId];
}

- (NSUInteger)engineId {
    NSAssert(self.luaRunner != nil, @"Engine did not loaded");
    return self.luaRunner.uid;
}

- (void)loadWithMainFile:(NSString *)mainFile completion:(void(^)(BOOL succeed, NSError *error))completion {
    [self _tryLoadFromMainBundleWithMainFile:mainFile completion:completion];
}

- (void)_tryLoadFromMainBundleWithMainFile:(NSString *)mainFile completion:(void(^)(BOOL succeed, NSError *error))completion {
    NSString *scripts = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:mainFile ofType:nil]
                                                  encoding:NSUTF8StringEncoding
                                                     error:nil];
    self.luaRunner = [[MMLuaRunner alloc] initWithScripts:[NSString stringWithFormat:@"%@", scripts]];
    [[TSEngineManager shared] addEngine:self];
    
    if (completion) {
        completion(YES, nil);
    }
}

- (void)_initLuaWithScriptBundlePath:(NSString *)bundlePath completed:(void(^)(BOOL, NSError *error))completed {
    TSRemoteLuaModuleSupport *moduleSupport = [[TSRemoteLuaModuleSupport alloc] initWithBundlePath:bundlePath];
    [MMLuaRunner setSharedModuleSupport:moduleSupport];
    NSString *script = [moduleSupport scriptForModuleName:@"main"];
    if (script.length == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completed) {
                completed(NO, [NSError errorWithDomain:NSStringFromClass([self class]) code:-7002 userInfo:@{NSLocalizedDescriptionKey : @"Can't find main script"}]);
            }
        });
    } else {
        self.luaRunner = [[MMLuaRunner alloc] initWithScripts:script];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completed) {
                completed(YES, nil);
            }
        });
    }
}

- (id<SFServant>)luaServiceWithName:(NSString *)serviceName params:(NSDictionary *)params {
    NSAssert(self.luaRunner != nil, @"Engine did not loaded");
    return [[SFWrappableServant alloc] initWithServant:[TSLuaService serviceWithLuaRunner:self.luaRunner serviceName:serviceName params:params]];
}

- (NSString *)resultValueByCallingFunction:(NSString *)function params:(NSArray *)params {
    NSAssert(self.luaRunner != nil, @"Engine did not loaded");
    return [self.luaRunner callFunctionWithName:function parameters:params].value;
}

- (id)JSONValueByCallingFunction:(NSString *)function params:(NSArray *)params {
    id JSON = nil;
    NSString *JSONString = [self resultValueByCallingFunction:function params:params];
    if (JSONString.length != 0) {
        JSON = [NSJSONSerialization JSONObjectWithData:[JSONString dataUsingEncoding:NSUTF8StringEncoding]
                                               options:0
                                                 error:nil];
    }
    
    return JSON;
}

@end
