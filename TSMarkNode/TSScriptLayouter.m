//
//  TSScriptLayouter.m
//  Markdown
//
//  Created by yangzexin on 2020/5/19.
//  Copyright © 2020 yangzexin. All rights reserved.
//

#import "TSScriptLayouter.h"
#import "TSScriptMindViewStyle.h"
#import "TSNode+LayoutAddition.h"
#import "TSStandardLayouter.h"
#import "TSLayouter+Private.h"

@interface TSScriptLayoutResult : NSObject

@property (nonatomic, assign) CGFloat x;
@property (nonatomic, assign) CGFloat y;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, assign) CGFloat displayX;
@property (nonatomic, assign) CGFloat displayY;
@property (nonatomic, assign) CGFloat displayWidth;
@property (nonatomic, assign) CGFloat displayHeight;
@property (nonatomic, assign) CGFloat titleX;
@property (nonatomic, assign) CGFloat titleY;
@property (nonatomic, assign) CGFloat titleWidth;
@property (nonatomic, assign) CGFloat titleHeight;
@property (nonatomic, assign) CGFloat connPointX;
@property (nonatomic, assign) CGFloat connPointY;
@property (nonatomic, assign) CGFloat plugPointX;
@property (nonatomic, assign) CGFloat plugPointY;

@property (nonatomic, assign) CGFloat allWidth;
@property (nonatomic, strong) NSArray *subnodes;

@end

@implementation TSScriptLayoutResult

@end

@implementation TSScriptLayouter

- (instancetype)initWithName:(NSString *)name engine:(TSLuaEngine *)engine {
    TSScriptLayouter *layouter = [TSScriptLayouter new];
    layouter.name = name;
    layouter.luaEngine = engine;
    
    return layouter;
}

- (TSNodeLayoutResult *)layout:(TSNode *)node size:(CGSize)size {
    NSMutableDictionary *nodeDict = [NSMutableDictionary dictionaryWithDictionary:[node dictionary]];
    [nodeDict addEntriesFromDictionary:@{@"layoutWidth": [NSNumber numberWithInteger:size.width], @"layoutHeight": [NSNumber numberWithInteger:size.height]}];
    __block NSDictionary *resultDict = nil;
    [self sf_sendServant:[self.luaEngine luaServiceWithName:@"Theme" params:@{@"action": @"layout", @"name": self.name, @"node": nodeDict}] success:^(NSString *value) {
        resultDict = [NSJSONSerialization JSONObjectWithData:[value dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    } error:^(NSError *error) {
        NSLog(@"Error on layouting: %@", node.title);
    }];
    id mapping = SFBeginPropertyMappingWithClass(TSScriptLayoutResult)
    SFMappingPropertyToClass(subnodes, TSScriptLayoutResult)
    SFEndPropertyMapping;
    NSArray *results = [TSScriptLayoutResult sf_objectFromDictionary:resultDict mapping:mapping];
    TSNodeLayoutResult *layoutResult = [self _layoutResultWithScriptResult:[results objectAtIndex:0] node:node];
    
    return layoutResult;
}

- (TSNodeLayoutResult *)_layoutResultWithScriptResult:(TSScriptLayoutResult *)result node:(TSNode *)node {
    TSNodeLayoutResult *layoutResult = [TSNodeLayoutResult new];
    layoutResult.node = node;
    layoutResult.frame = CGRectMake(result.x, result.y, result.width, result.height);
    layoutResult.allWidth = result.allWidth;
    layoutResult.connectionPoint = CGPointMake(result.connPointX, result.connPointY);
    layoutResult.plugPoint = CGPointMake(result.plugPointX, result.plugPointY);
    layoutResult.displayRect = CGRectMake(result.displayX, result.displayY, result.displayWidth, result.displayHeight);
    layoutResult.titleFrame = CGRectMake(result.titleX, result.titleY, result.titleWidth, result.titleHeight);
    
    NSMutableArray *subResults = [NSMutableArray array];
    for (NSUInteger i = 0; i < result.subnodes.count; ++i) {
        TSScriptLayoutResult *subScriptResult = [result.subnodes objectAtIndex:i];
        TSNode *subNode = [node.subnodes objectAtIndex:i];
        TSNodeLayoutResult *subResult = [self _layoutResultWithScriptResult:subScriptResult node:subNode];
        [subResults addObject:subResult];
    }
    layoutResult.subNodeResults = subResults;
    
    return layoutResult;
}

+ (nullable NSArray<NSString *> *)layouterNamesWithLuaEngine:(TSLuaEngine *)luaEngine {
    __block NSString *result = nil;
    [self sf_sendServant:[luaEngine luaServiceWithName:@"Theme" params:@{@"action": @"layouterNames"}] success:^(id value) {
        result = value;
    } error:^(NSError *error) {
        NSLog(@"Warning: load layouter name failed: %@", [error localizedDescription]);
    }];
    if (result != nil && result.length > 0) {
        return [result componentsSeparatedByString:@","];
    }
    
    return nil;
}

- (BOOL)shouldStartDragging {
    return NO;
}

- (BOOL)shouldPerformDragWithDraggingNode:(TSNode *)draggingNode draggingFrame:(CGRect)draggingFrame targetDisplayRect:(CGRect)displayRect closingToTarget:(TSNodeLayoutResult *)target tempNode:(TSNode *)tempNode {
    return NO;
}

- (id<TSMindViewStyle>)preferedMindViewStyle {
    NSAssert(self.luaEngine != nil, @"lua engine cannot be nil");
    NSString *result = [self.luaEngine resultValueByCallingFunction:@"supportStyle" params:@[]];
    if (![@"1" isEqualToString:result]) {
        return nil;
    }
    TSScriptMindViewStyle *style = [TSScriptMindViewStyle new];
    style.luaEngine = self.luaEngine;
    
    return style;
}

@end
