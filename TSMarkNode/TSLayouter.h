//
//  TSLayouter.h
//  TSMarkNode
//
//  Created by yangzexin on 2020/5/13.
//  Copyright © 2020 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TSNodeStyle.h"

@class TSNode;

NS_ASSUME_NONNULL_BEGIN

@interface TSNodeLayoutResult : NSObject

// The frame of single node
@property (nonatomic, assign, readonly) CGRect frame;

// Results of subnodes
@property (nonatomic, strong, readonly, nullable) NSArray<TSNodeLayoutResult *> *subNodeResults;

// As a parent node, source point of connection line
@property (nonatomic, assign) CGPoint connectionPoint;

// As a sub node, connection point of connection line
@property (nonatomic, assign) CGPoint plugPoint;

// The width that contains all subnodes
@property (nonatomic, assign, readonly) CGFloat allWidth;

// The display rectangle of node
@property (nonatomic, assign) CGRect displayRect;

// The title frame
@property (nonatomic, assign) CGRect titleFrame;

// Associated node
@property (nonatomic, weak, readonly, nullable) TSNode *node;

/**
 Traverse result
 - parameter result: The node result
 - parameter reverse: The traverse order of sub results
 - parameter block: callback
 */
+ (void)traverseWithResult:(TSNodeLayoutResult *)result reverse:(BOOL)reverse block:(void(^)(TSNodeLayoutResult *result, BOOL *stop))block;

/**
 Traverse result by normal order
 - parameter result: The node result
 - parameter block: callback
 */
+ (void)traverseWithResult:(TSNodeLayoutResult *)result block:(void(^)(TSNodeLayoutResult *result, BOOL *stop))block;

@end

@interface TSLayoutResult : NSObject

// The result of root node
@property (nonatomic, strong, readonly) TSNodeLayoutResult *nodeLayoutResult;

// Initial display rect
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

/**
 Get limit size of node
 */
- (TSLimitedSize)layouter:(id<TSLayouter>)layouter limitedSizeForNode:(TSNode *)node;

/**
 Get padding of node
 */
- (CGFloat)layouter:(id<TSLayouter>)layouter paddingForNode:(TSNode *)node;

/**
 Get font of node's title
 */
- (UIFont *)layouter:(id<TSLayouter>)layouter fontForNode:(TSNode *)node;

/**
 Get spacing of node
 */
- (TSSpacing)layouter:(id<TSLayouter>)layouter spacingForNode:(TSNode *)node;

/**
 Get sub aligment of node
 */
- (TSNodeSubAlignment)layouter:(id<TSLayouter>)layouter subAlignmentForNode:(TSNode *)node;

@end

@protocol TSLayouter <NSObject>

// Name of layouter
@property (nonatomic, copy) NSString *name;

// Delegate
@property (nonatomic, weak) id<TSLayouterDelegate> delegate;

/**
 Layout specified node by constrainted size of container.
 - parameter node: Root node
 - parameter size: Size of conatiner
 - returns: The layout result of all nodes and initial display rect.
 */
- (TSLayoutResult *)layout:(TSNode *)node size:(CGSize)size;

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

// Abstract class
@interface TSLayouter : NSObject <TSLayouter>

@property (nonatomic, copy) NSString *name;
@property (nonatomic, weak) id<TSLayouterDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
