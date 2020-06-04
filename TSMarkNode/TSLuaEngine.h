//
//  TSLuaEngine.h
//  TSMarkNode
//
//  Created by yangzexin on 2020/5/18.
//  Copyright © 2020 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SFFoundation/SFFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TSLuaEngine : NSObject

@property (nonatomic, assign, readonly) NSUInteger engineId;

+ (instancetype)engineFromMainBundle;

+ (instancetype)engineByFindingWithId:(NSUInteger)engineId;

- (void)loadWithMainFile:(NSString *)mainFile completion:(void(^)(BOOL succeed, NSError * _Nullable error))completion;

- (NSString *)resultValueByCallingFunction:(NSString *)function params:(NSArray *)params;

- (id<SFServant>)luaServiceWithName:(NSString *)serviceName params:(NSDictionary *)params;

@end

NS_ASSUME_NONNULL_END
