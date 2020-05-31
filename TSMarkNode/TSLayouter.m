//
//  TSLayouter.m
//  Markdown
//
//  Created by yangzexin on 2020/5/13.
//  Copyright © 2020 yangzexin. All rights reserved.
//

#import "TSLayouter.h"
#import "TSLayouter+Private.h"
#import "TSNode.h"
#import "TSNode+LayoutAddition.h"
#import "TSNodeStyle.h"

@implementation TSLayoutResult

+ (void)traverseWithResult:(TSLayoutResult *)result reverse:(BOOL)reverse block:(void(^)(TSLayoutResult *result, BOOL *stop))block {
    BOOL stop = NO;
    block(result, &stop);
    if (stop) {
        return;
    }
    if (result.subNodeResults != nil && result.subNodeResults.count > 0) {
        for (NSUInteger i = 0; i < result.subNodeResults.count; ++i) {
            TSLayoutResult *subResult = [result.subNodeResults objectAtIndex:reverse ? (result.subNodeResults.count - 1 - i) : i];
            [self traverseWithResult:subResult block:block];
        }
    }
}

+ (void)traverseWithResult:(TSLayoutResult *)result block:(void(^)(TSLayoutResult *result, BOOL *stop))block {
    [self traverseWithResult:result reverse:NO block:block];
}

@end

@implementation TSLayouter

- (instancetype)initWithDelegate:(id<TSLayouterDelegate>)delegate {
    self = [super init];
    
    self.delegate = delegate;
    
    return self;
}

- (TSLayoutResult *)layout:(TSNode *)node size:(CGSize)size {
    NSAssert(YES, @"This method should be implemented by subclass");
    return nil;
}

- (BOOL)shouldPerformDragWithDraggingNode:(TSNode *)draggingNode draggingFrame:(CGRect)draggingFrame targetDisplayRect:(CGRect)displayRect closingToTarget:(TSLayoutResult *)target tempNode:(TSNode *)tempNode {
    NSAssert(YES, @"This method should be implemented by subclass");
    return NO;
}

- (BOOL)shouldStartDragging {
    NSAssert(YES, @"This method should be implemented by subclass");
    return NO;
}


@end
