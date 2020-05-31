//
//  TSLayouter.h
//  Markdown
//
//  Created by yangzexin on 2020/5/13.
//  Copyright © 2020 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <SFiOSKit/SFiOSKit.h>
#import "TSNodeStyle.h"

@class TSNode;

NS_ASSUME_NONNULL_BEGIN

@interface TSLayoutResult : NSObject

@property (nonatomic, assign, readonly) CGRect frame;
@property (nonatomic, strong, readonly, nullable) NSArray<TSLayoutResult *> *subNodeResults;
@property (nonatomic, assign) CGPoint connectionPoint;
@property (nonatomic, assign) CGPoint plugPoint;

@property (nonatomic, assign, readonly) CGFloat allWidth;

@property (nonatomic, assign) CGRect displayRect;
@property (nonatomic, assign) CGRect titleFrame;

@property (nonatomic, weak, readonly, nullable) TSNode *node;

+ (void)traverseWithResult:(TSLayoutResult *)result reverse:(BOOL)reverse block:(void(^)(TSLayoutResult *result, BOOL *stop))block;

+ (void)traverseWithResult:(TSLayoutResult *)result block:(void(^)(TSLayoutResult *result, BOOL *stop))block;

@end

@protocol TSLayouter;

typedef struct {
    CGFloat maxWidth;
    CGFloat minWidth;
} TSLimitedSize;

typedef struct {
    CGFloat vertical;
    CGFloat horizontal;
} TSSpacing;

@protocol TSLayouterDelegate <NSObject>

- (TSLimitedSize)layouter:(id<TSLayouter>)layouter limitedSizeForNode:(TSNode *)node;
- (CGFloat)layouter:(id<TSLayouter>)layouter paddingForNode:(TSNode *)node;
- (UIFont *)layouter:(id<TSLayouter>)layouter fontForNode:(TSNode *)node;
- (TSSpacing)layouter:(id<TSLayouter>)layouter spacingForNode:(TSNode *)node;
- (TSNodeSubAlignment)layouter:(id<TSLayouter>)layouter subAlignmentForNode:(TSNode *)node;

@end

@protocol TSLayouter <NSObject>

@property (nonatomic, copy) NSString *name;
@property (nonatomic, weak) id<TSLayouterDelegate> delegate;

- (TSLayoutResult *)layout:(TSNode *)node size:(CGSize)size;

- (BOOL)shouldStartDragging;

- (BOOL)shouldPerformDragWithDraggingNode:(TSNode *)draggingNode draggingFrame:(CGRect)draggingFrame targetDisplayRect:(CGRect)displayRect closingToTarget:(TSLayoutResult *)target tempNode:(TSNode *)tempNode;

@optional
- (NSTextAlignment)textAlignmentForNode:(TSNode *)node textSize:(CGSize)textSize nodeStyle:(id<TSNodeStyle>)nodeStyle originalAlignment:(NSTextAlignment)originalAlignment;

- (id<TSMindViewStyle>)preferedMindViewStyle;

@end

@interface TSLayouter : NSObject <TSLayouter>

@property (nonatomic, copy) NSString *name;
@property (nonatomic, weak) id<TSLayouterDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
