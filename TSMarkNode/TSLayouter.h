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

@interface TSNodeLayoutResult : NSObject

@property (nonatomic, assign, readonly) CGRect frame;
@property (nonatomic, strong, readonly, nullable) NSArray<TSNodeLayoutResult *> *subNodeResults;
@property (nonatomic, assign) CGPoint connectionPoint;
@property (nonatomic, assign) CGPoint plugPoint;

@property (nonatomic, assign, readonly) CGFloat allWidth;

@property (nonatomic, assign) CGRect displayRect;
@property (nonatomic, assign) CGRect titleFrame;

@property (nonatomic, weak, readonly, nullable) TSNode *node;

+ (void)traverseWithResult:(TSNodeLayoutResult *)result reverse:(BOOL)reverse block:(void(^)(TSNodeLayoutResult *result, BOOL *stop))block;

+ (void)traverseWithResult:(TSNodeLayoutResult *)result block:(void(^)(TSNodeLayoutResult *result, BOOL *stop))block;

@end

@interface TSLayoutResult : NSObject

@property (nonatomic, strong, readonly) TSNodeLayoutResult *nodeLayoutResult;
@property (nonatomic, assign, readonly) CGRect initialDisplayRect;

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

/**
 Layout specified node by constrainted size of container.
 - parameter node: Root node
 - parameter size: Size of conatiner
 - returns: The layout result of all nodes and initial display rect.
 */
- (TSNodeLayoutResult *)layout:(TSNode *)node size:(CGSize)size;

/**
 Check if layouter support dragging
 - returns: YES if layouter support dragging
 */
- (BOOL)shouldStartDragging;

/**
 Determine which node that closing to dragging node can be placed
 - parameter draggingNode: The dragging node
 - parameter draggingFrame: The frame of dragging node
 - parameter displayRect: The display rect of closing node
 - parameter tempNode: The node temporary created by dragging
 - returns: YES if dragging performed and tempNode added
 */
- (BOOL)shouldPerformDragWithDraggingNode:(TSNode *)draggingNode draggingFrame:(CGRect)draggingFrame targetDisplayRect:(CGRect)displayRect closingToTarget:(TSNodeLayoutResult *)target tempNode:(TSNode *)tempNode;

@optional
/**
 Chance for changing text alignment for node
 - parameter node: node
 - parameter textSize: The text size(width, height) of node's title
 - parameter nodeStyle: Node style of node
 - parameter originalAlignment: Original text alignment
 - returns: New text alignment
 */
- (NSTextAlignment)textAlignmentForNode:(TSNode *)node textSize:(CGSize)textSize nodeStyle:(id<TSNodeStyle>)nodeStyle originalAlignment:(NSTextAlignment)originalAlignment;

/**
 Chance to replacing style of mind view
 - returns: The new style, or nil if still use default style
 */
- (id<TSMindViewStyle>)preferedMindViewStyle;

@end

@interface TSLayouter : NSObject <TSLayouter>

@property (nonatomic, copy) NSString *name;
@property (nonatomic, weak) id<TSLayouterDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
