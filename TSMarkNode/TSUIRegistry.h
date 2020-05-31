//
//  TSLayouterRegistry.h
//  Markdown
//
//  Created by yangzexin on 2020/5/21.
//  Copyright © 2020 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSLayouter.h"
#import "TSNodeStyle.h"

NS_ASSUME_NONNULL_BEGIN

@interface TSLayouterRegistry : NSObject

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) id<TSLayouter>(^create)(void);

+ (instancetype)registryWithName:(NSString *)name create:(id<TSLayouter>(^)(void))create;

@end

@interface TSMindViewStyleRegistry : NSObject

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) id<TSMindViewStyle>(^create)(void);

+ (instancetype)registryWithName:(NSString *)name create:(id<TSMindViewStyle>(^)(void))create;

@end

@interface TSUIRegistries : NSObject

+ (instancetype)shared;

- (void)addLayoutRegistry:(TSLayouterRegistry *)registry;
- (void)removeLayoutRegistry:(TSLayouterRegistry *)registry;

- (NSArray<TSLayouterRegistry *> *)allLayoutRegistries;
- (NSArray<NSString *> *)allLayoutNames;

- (void)addStyleRegistry:(TSMindViewStyleRegistry *)registry;
- (void)removeStyleRegistry:(TSMindViewStyleRegistry *)registry;

- (NSArray<TSMindViewStyleRegistry *> *)allStyleRegistries;
- (NSArray<NSString *> *)allStyleNames;

@end

NS_ASSUME_NONNULL_END
