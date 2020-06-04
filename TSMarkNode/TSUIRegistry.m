//
//  TSUIRegistry.m
//  TSMarkNode
//
//  Created by yangzexin on 2020/5/21.
//  Copyright © 2020 yangzexin. All rights reserved.
//

#import "TSUIRegistry.h"

@interface TSLayouterRegistry ()

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) id<TSLayouter>(^create)(void);

@end

@implementation TSLayouterRegistry

+ (instancetype)registryWithName:(NSString *)name create:(id<TSLayouter>(^)(void))create {
    TSLayouterRegistry *layouter = [TSLayouterRegistry new];
    layouter.name = name;
    layouter.create = create;
    
    return layouter;
}

@end

@interface TSMindViewStyleRegistry ()

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) id<TSMindViewStyle>(^create)(void);

@end

@implementation TSMindViewStyleRegistry

+ (instancetype)registryWithName:(NSString *)name create:(id<TSMindViewStyle>(^)(void))create {
    TSMindViewStyleRegistry *style = [TSMindViewStyleRegistry new];
    style.name = name;
    style.create = create;
    
    return style;
}

@end

@interface TSUIRegistries ()

@property (nonatomic, strong) NSMutableArray<TSLayouterRegistry *> *layoutRegistries;
@property (nonatomic, strong) NSMutableArray<TSMindViewStyleRegistry *> *styleRegistries;

@end

@implementation TSUIRegistries

- (id)init {
    self = [super init];
    
    self.layoutRegistries = [NSMutableArray array];
    self.styleRegistries = [NSMutableArray array];
    
    return self;
}

+ (instancetype)shared {
    static TSUIRegistries *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self class] new];
    });
    
    return instance;
}

- (void)addLayoutRegistry:(TSLayouterRegistry *)registry {
    [self.layoutRegistries addObject:registry];
}

- (void)removeLayoutRegistry:(TSLayouterRegistry *)registry {
    [self.layoutRegistries removeObject:registry];
}

- (NSArray<TSLayouterRegistry *> *)allLayoutRegistries {
    return [self.layoutRegistries copy];
}

- (NSArray<NSString *> *)allLayoutNames {
    NSArray<TSLayouterRegistry *> *registries = [self allLayoutRegistries];
    NSMutableArray<NSString *> *names = [NSMutableArray array];
    for (TSLayouterRegistry *registry in registries) {
        [names addObject:registry.name];
    }
    
    return names;
}

- (void)addStyleRegistry:(TSMindViewStyleRegistry *)registry {
    [self.styleRegistries addObject:registry];
}

- (void)removeStyleRegistry:(TSMindViewStyleRegistry *)registry {
    [self.styleRegistries removeObject:registry];
}

- (NSArray<TSMindViewStyleRegistry *> *)allStyleRegistries {
    return [self.styleRegistries copy];
}

- (NSArray<NSString *> *)allStyleNames {
    NSArray<TSMindViewStyleRegistry *> *registries = [self allStyleRegistries];
    NSMutableArray<NSString *> *names = [NSMutableArray array];
    for (TSMindViewStyleRegistry *registry in registries) {
        [names addObject:registry.name];
    }
    
    return names;
}

@end
