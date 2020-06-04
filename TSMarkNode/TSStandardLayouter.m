//
//  TSStandardLayouter.m
//  TSMarkNode
//
//  Created by yangzexin on 2020/5/20.
//  Copyright © 2020 yangzexin. All rights reserved.
//

#import "TSStandardLayouter.h"
#import "TSLayouter+Private.h"
#import "TSNode.h"
#import "TSNode+LayoutAddition.h"
#import <SFiOSKit/SFiOSKit.h>

@interface TSNode (StandardLayoutAddition)

@property (nonatomic, strong) NSMutableArray *leftNodes;
@property (nonatomic, strong) NSMutableArray *rightNodes;

@end

@implementation TSNode (StandardLayoutAddition)

- (NSMutableArray *)leftNodes {
    return [self sf_associatedObjectWithKey:@"_leftNodes"];
}

- (void)setLeftNodes:(NSMutableArray *)leftNodes {
    [self sf_setAssociatedObject:leftNodes key:@"_leftNodes"];
    [self addNewSubnodeObserver:^(TSNode * _Nonnull newSubnode) {
        
    }];
}

- (NSMutableArray *)rightNodes {
    return [self sf_associatedObjectWithKey:@"_rightNodes"];
}

- (void)setRightNodes:(NSMutableArray *)rightNodes {
    [self sf_setAssociatedObject:rightNodes key:@"_rightNodes"];
}

@end

@interface TSStandardLayouter ()

@property (nonatomic, strong) TSNode *node;
@property (nonatomic, strong) NSMutableArray *leftNodes;
@property (nonatomic, strong) NSMutableArray *rightNodes;

@end

@implementation TSStandardLayouter

- (instancetype)init {
    self = [super init];
    
    self.name = @"Standard";
    
    return self;
}

- (void)_calculateNodeSize:(TSNode *)node result:(TSNodeLayoutResult *)result {
    UIFont *font = [self.delegate layouter:self fontForNode:node];
    TSLimitedSize limitedSize = [self.delegate layouter:self limitedSizeForNode:node];
    CGFloat textMaxWidth = limitedSize.maxWidth;
    CGFloat textMinWidth = limitedSize.minWidth;
    CGSize titleSize = [node.title sf_sizeWithFont:font constrainedToSize:CGSizeMake(textMaxWidth, MAXFLOAT)];
    if (titleSize.width < textMinWidth) {
        titleSize.width = textMinWidth;
    }
    const CGFloat padding = [self.delegate layouter:self paddingForNode:node];
    result.displayRect = CGRectMake(0, 0, titleSize.width + padding * 2, titleSize.height + padding * 2);
    result.titleFrame = CGRectMake(padding, padding, titleSize.width, titleSize.height);
}

- (TSLayoutResult *)layout:(TSNode *)node size:(CGSize)size {
    TSLayoutResult *layoutResult = [TSLayoutResult new];
    
    NSMutableArray *leftNodes = self.leftNodes;
    NSMutableArray *rightNodes = self.rightNodes;
    
    if (self.node != node) {
        self.node = node;
        leftNodes = [NSMutableArray array];
        rightNodes = [NSMutableArray array];
        
        NSUInteger totalCount = node.subnodes.count;
        NSUInteger subCount = totalCount / 2;
        
        __weak typeof(self) weakSelf = self;
        for (NSUInteger i = 0; i < totalCount; ++i) {
            TSNode *subNode = [node.subnodes objectAtIndex:i];
            NSMutableArray *nodes = i < subCount ? leftNodes : rightNodes;
            [nodes addObject:subNode];
            
            __weak typeof(nodes) weakNodes = nodes;
            __weak typeof(subNode) weakSubNode = subNode;
            [subNode addRemoveObserver:^{
                //NSLog(@"%@ remove: %@, %@", weakNodes == weakSelf.leftNodes ? @"left" : @"right", weakSubNode, weakSubNode.title);
                [weakNodes removeObject:weakSubNode];
            }];
        }
        
        self.leftNodes = leftNodes;
        self.rightNodes = rightNodes;
        
        [node addNewSubnodeObserver:^(TSNode * _Nonnull subNode) {
            __strong typeof(self) self = weakSelf;
            NSMutableArray *nodes = self.leftNodes.count > self.rightNodes.count ? self.rightNodes : self.leftNodes;
            //NSLog(@"%@ add: %@, %@", nodes == weakSelf.leftNodes ? @"left" : @"right", subNode, subNode.title);
            [nodes addObject:subNode];
            
            __weak typeof(nodes) weakNodes = nodes;
            __weak typeof(subNode) weakSubNode = subNode;
            [subNode addRemoveObserver:^{
                //NSLog(@"%@ remove: %@, %@", weakNodes == weakSelf.leftNodes ? @"left" : @"right", weakSubNode, weakSubNode.title);
                [weakNodes removeObject:weakSubNode];
            }];
        }];
    }
    TSNodeLayoutResult *rootResult = [self _calculateNodeSize:node displayLevel:0 hanleSubNodes:NO];
    
    NSMutableArray *leftResults = [NSMutableArray array];
    CGFloat leftMaxWidth = .0f;
    CGFloat leftTotalHeight = .0f;
    for (NSUInteger i = 0; i < leftNodes.count; ++i) {
        TSNode *leftSubNode = [leftNodes objectAtIndex:i];
        TSNodeLayoutResult *leftSubResult = [self _calculateNodeSize:leftSubNode displayLevel:1 hanleSubNodes:YES];
        leftSubResult.parent = rootResult;
        leftTotalHeight += leftSubResult.frame.size.height;
        if (i != leftNodes.count - 1) {
            TSSpacing spacing = [self.delegate layouter:self spacingForNode:leftSubNode];
            leftTotalHeight += spacing.vertical;
        }
        
        [leftResults addObject:leftSubResult];
    }
    CGFloat leftOffsetY = (size.height - leftTotalHeight) / 2;
    for (NSUInteger i = 0; i < leftResults.count; ++i) {
        TSNodeLayoutResult *leftSubResult = [leftResults objectAtIndex:i];
        TSSpacing spacing = [self.delegate layouter:self spacingForNode:leftSubResult.node];
        CGFloat maxWidth = [self _setNodePosition:leftSubResult offsetX:0 offsetY:leftOffsetY left:YES] - spacing.horizontal;
        if (maxWidth > leftMaxWidth) {
            leftMaxWidth = maxWidth;
        }
        leftOffsetY += leftSubResult.frame.size.height + spacing.vertical;
    }
    
    CGFloat centerX = size.width / 2;
    for (NSUInteger i = 0; i < leftResults.count; ++i) {
        TSNodeLayoutResult *leftSubResult = [leftResults objectAtIndex:i];
        TSSpacing spacing = [self.delegate layouter:self spacingForNode:leftSubResult.node];
        [self _setLeftNodePosition:leftSubResult containerWidth:leftMaxWidth offsetX:centerX - leftMaxWidth - spacing.horizontal - rootResult.frame.size.width / 2];
    }
    
    NSMutableArray *rightResults = [NSMutableArray array];
    CGFloat rightMaxWidth = .0f;
    CGFloat rightTotalHeight = .0f;
    for (NSUInteger i = 0; i < rightNodes.count; ++i) {
        TSNode *rightSubNode = [rightNodes objectAtIndex:i];
        TSNodeLayoutResult *rightSubResult = [self _calculateNodeSize:rightSubNode displayLevel:1 hanleSubNodes:YES];
        rightSubResult.parent = rootResult;
        rightTotalHeight += rightSubResult.frame.size.height;
        if (i != rightNodes.count - 1) {
            TSSpacing spacing = [self.delegate layouter:self spacingForNode:rightSubNode];
            rightTotalHeight += spacing.vertical;
        }
        
        [rightResults addObject:rightSubResult];
    }
    CGFloat rightOffsetY = (size.height - rightTotalHeight) / 2;
    TSSpacing rootNodeSpacing = [self.delegate layouter:self spacingForNode:node];
    CGFloat rightX = centerX + rootResult.frame.size.width / 2 + rootNodeSpacing.horizontal;
    for (NSUInteger i = 0; i < rightResults.count; ++i) {
        TSNodeLayoutResult *rightSubResult = [rightResults objectAtIndex:i];
        TSSpacing spacing = [self.delegate layouter:self spacingForNode:rightSubResult.node];
        CGFloat maxWidth = [self _setNodePosition:rightSubResult offsetX:rightX offsetY:rightOffsetY left:NO] - spacing.horizontal;
        if (maxWidth > rightMaxWidth) {
            rightMaxWidth = maxWidth;
        }
        rightOffsetY += rightSubResult.frame.size.height + spacing.vertical;
    }
    
    rootResult.allWidth = leftMaxWidth + rightMaxWidth;
    CGRect frame = rootResult.frame;
    frame.size = CGSizeMake(frame.size.width, MAX(leftTotalHeight, rightTotalHeight));
    frame.origin = CGPointMake((size.width - frame.size.width) / 2, (size.height - frame.size.height) / 2);
    rootResult.frame = frame;
    rootResult.connectionPoint = CGPointMake(size.width / 2, size.height / 2);
    CGRect displayRect = rootResult.displayRect;
    displayRect.origin = CGPointMake((rootResult.frame.size.width - rootResult.displayRect.size.width) / 2, (rootResult.frame.size.height - rootResult.displayRect.size.height) / 2);
    rootResult.displayRect = displayRect;
    rootResult.subNodeResults = ({
        NSMutableArray *all = [NSMutableArray arrayWithArray:leftResults];
        [all addObjectsFromArray:rightResults];
        all;
    });
    
    layoutResult.nodeLayoutResult = rootResult;
    layoutResult.initialDisplayRect = CGRectZero;
    
    return layoutResult;
}

- (void)_setLeftNodePosition:(TSNodeLayoutResult *)result containerWidth:(CGFloat)containerWidth offsetX:(CGFloat)offsetX {
    CGRect frame = result.frame;
    frame.origin.x = offsetX + containerWidth - frame.origin.x - frame.size.width;
    result.frame = frame;
    
    for (TSNodeLayoutResult *subResult in result.subNodeResults) {
        [self _setLeftNodePosition:subResult containerWidth:containerWidth offsetX:offsetX];
    }
    
    CGRect displayRect = result.displayRect;
    TSNodeSubAlignment subAlignment = [self.delegate layouter:self subAlignmentForNode:result.node];
    if (subAlignment == TSNodeSubAlignmentTop) {
        CGFloat displayY = 0;
        TSNodeLayoutResult *firstResult = [result.subNodeResults firstObject];
        if (result.subNodeResults.count == 1) {
            displayY = displayRect.origin.y;
            displayY += firstResult.frame.size.height / 2;
        } else if (result.subNodeResults.count > 1) {
            TSNodeLayoutResult *lastResult = [result.subNodeResults lastObject];
            CGFloat firstResutPlugPointY = firstResult.plugPoint.y;
            CGFloat lastResultPlugPointY = lastResult.plugPoint.y;
            CGFloat centerY = firstResutPlugPointY + (lastResultPlugPointY - firstResutPlugPointY) / 2 - result.frame.origin.y;
            displayY = centerY - displayRect.size.height / 2;
        }
        displayRect.origin.y = displayY;
        result.displayRect = displayRect;
    }
    
    result.connectionPoint = CGPointMake(frame.origin.x + frame.size.width / 2, frame.origin.y + displayRect.origin.y + displayRect.size.height / 2);
    TSNodeSubAlignment parentSubAlignment = [self.delegate layouter:self subAlignmentForNode:result.parent.node];
    result.plugPoint = CGPointMake(frame.origin.x + frame.size.width, frame.origin.y + displayRect.origin.y + (parentSubAlignment == TSNodeSubAlignmentTop ? (result.displayRect.size.height) : (result.displayRect.size.height / 2)));
}

- (CGFloat)_setNodePosition:(TSNodeLayoutResult *)result offsetX:(CGFloat)offsetX offsetY:(CGFloat)offsetY left:(BOOL)left {
    CGRect frame = result.frame;
    frame.origin = CGPointMake(offsetX, offsetY);
    result.frame = frame;
    
    CGRect displayRect = result.displayRect;
    displayRect.origin = CGPointMake((result.frame.size.width - displayRect.size.width) / 2, (result.frame.size.height - displayRect.size.height) / 2);
    result.displayRect = displayRect;
    
    CGFloat subNodesHeight = .0f;
    for (NSUInteger i = 0; i < result.subNodeResults.count; ++i) {
        TSNodeLayoutResult *subResult = [result.subNodeResults objectAtIndex:i];
        subNodesHeight += subResult.frame.size.height;
        if (i != result.subNodeResults.count - 1) {
            TSSpacing spacing = [self.delegate layouter:self spacingForNode:subResult.node];
            subNodesHeight += spacing.vertical;
        }
    }
    offsetY += (frame.size.height - subNodesHeight) / 2;
    
    TSSpacing spacing = [self.delegate layouter:self spacingForNode:result.node];
    CGFloat maxWidth = offsetX + result.frame.size.width + spacing.horizontal;
    for (TSNodeLayoutResult *subResult in result.subNodeResults) {
        TSSpacing subSpacing = [self.delegate layouter:self spacingForNode:subResult.node];
        CGFloat nextOffsetX = offsetX + result.frame.size.width + subSpacing.horizontal;
        CGFloat nextOffsetY = offsetY;
        CGFloat subNodeMaxWidth = [self _setNodePosition:subResult offsetX:nextOffsetX offsetY:nextOffsetY left:left];
        offsetY += subResult.frame.size.height + subSpacing.vertical;
        if (subNodeMaxWidth > maxWidth) {
            maxWidth = subNodeMaxWidth;
        }
    }
    
    if (!left) {
        TSNodeSubAlignment subAlignment = [self.delegate layouter:self subAlignmentForNode:result.node];
        if (subAlignment == TSNodeSubAlignmentTop) {
            // Adjust y of displayRect
            CGFloat displayY = 0;
            TSNodeLayoutResult *firstResult = [result.subNodeResults firstObject];
            if (result.subNodeResults.count == 1) {
                displayY = displayRect.origin.y;
                displayY += firstResult.frame.size.height / 2;
            } else if (result.subNodeResults.count > 1) {
                TSNodeLayoutResult *lastResult = [result.subNodeResults lastObject];
                CGFloat firstResutPlugPointY = firstResult.plugPoint.y;
                CGFloat lastResultPlugPointY = lastResult.plugPoint.y;
                CGFloat centerY = firstResutPlugPointY + (lastResultPlugPointY - firstResutPlugPointY) / 2 - result.frame.origin.y;
                displayY = centerY - displayRect.size.height / 2;
            }
            displayRect.origin.y = displayY;
            result.displayRect = displayRect;
        }
        
        result.connectionPoint = CGPointMake(frame.origin.x + frame.size.width / 2, frame.origin.y + displayRect.origin.y + displayRect.size.height / 2);
        TSNodeSubAlignment parentSubAlignment = [self.delegate layouter:self subAlignmentForNode:result.parent.node];
        result.plugPoint = CGPointMake(frame.origin.x, frame.origin.y + displayRect.origin.y + (parentSubAlignment == TSNodeSubAlignmentTop ? (result.displayRect.size.height) : (result.displayRect.size.height / 2)));
    }
    
    return maxWidth;
}

- (TSNodeLayoutResult *)_calculateNodeSize:(TSNode *)node displayLevel:(NSUInteger)displayLevel hanleSubNodes:(BOOL)handleSubNodes {
    TSNodeLayoutResult *result = [TSNodeLayoutResult new];
    result.node = node;
    node.displayLevel = [NSNumber numberWithUnsignedInteger:displayLevel];
    
    [self _calculateNodeSize:node result:result];
    CGSize nodeSize = result.displayRect.size;
    
    if (handleSubNodes) {
        NSArray<TSNode *> *nodes = node.subnodes;
        CGFloat maxSubNodeWidth = .0f;
        CGFloat totalHeight = .0f;
        const NSUInteger numOfNodes = nodes.count;
        NSMutableArray<TSNodeLayoutResult *> *subNodeLayoutResults = [NSMutableArray array];
        for (NSUInteger i = 0; i < numOfNodes; ++i) {
            TSNode *subNode = [nodes objectAtIndex:i];
            TSNodeLayoutResult *subResult = [self _calculateNodeSize:subNode displayLevel:displayLevel + 1 hanleSubNodes:YES];
            subResult.parent = result;
            [subNodeLayoutResults addObject:subResult];
            if (subResult.frame.size.width > maxSubNodeWidth) {
                maxSubNodeWidth = subResult.frame.size.width;
            }
            totalHeight += subResult.frame.size.height;
            if (i != numOfNodes - 1) {
                TSSpacing spacing = [self.delegate layouter:self spacingForNode:subNode];
                totalHeight += spacing.vertical;
            }
        }
        result.subNodeResults = subNodeLayoutResults;
        CGFloat nodeHeight = nodeSize.height;
        if (totalHeight > nodeHeight) {
            nodeHeight = totalHeight;
        }
        TSNodeSubAlignment subAlignment = [self.delegate layouter:self subAlignmentForNode:result.node];
        if (subAlignment == TSNodeSubAlignmentTop && subNodeLayoutResults.count == 1) {
            // Additional height for displaying only 1 sub node
            TSNodeLayoutResult *firstResult = [subNodeLayoutResults firstObject];
            if (nodeHeight < firstResult.frame.size.height * 2) {
                nodeHeight = firstResult.frame.size.height + nodeSize.height;
            }
        }
        nodeSize.height = nodeHeight;
    }
    result.frame = CGRectMake(0, 0, nodeSize.width, nodeSize.height);
    
    return result;
}

- (BOOL)shouldStartDragging {
    return YES;
}

- (BOOL)shouldPerformDragWithDraggingNode:(TSNode *)draggingNode draggingFrame:(CGRect)draggingFrame targetDisplayRect:(CGRect)displayRect closingToTarget:(TSNodeLayoutResult *)target tempNode:(TSNode *)tempNode {
    CGRect topFrame = draggingFrame;
    topFrame.size.height = 20;
    if (CGRectIntersectsRect(topFrame, displayRect)) {
        NSLog(@"try to as sub: %@", target.node.title);
        if ([target.node addNodeAsSub:tempNode exceptNode:draggingNode]) {
            NSLog(@"add to target node as sub: %@", target.node.title);
            return YES;
        }
    } else if (topFrame.origin.y + topFrame.size.height < displayRect.origin.y + displayRect.size.height / 2) {
        NSLog(@"try to as previous: %@", target.node.title);
        if ([target.node addNodeAsPreviousSibling:tempNode exceptNode:draggingNode]) {
            NSLog(@"add to target node as previous: %@", target.node.title);
            if (target.node.parent == self.node) {
                // first level node
                NSMutableArray *targetNodeList = self.leftNodes;
                NSUInteger index = [self.leftNodes indexOfObject:target.node];
                if (index == NSNotFound) {
                    targetNodeList = self.rightNodes;
                    index = [self.rightNodes indexOfObject:target.node];
                }
                if (index == NSNotFound) {
                    NSLog(@"Warning, cannot find node in leftNodes or rightNodes");
                    [tempNode removeFromParent];
                    return NO;
                }
                [targetNodeList insertObject:tempNode atIndex:index];
                __weak typeof(targetNodeList) weakTargetNodeList = targetNodeList;
                __weak typeof(tempNode) weakTempNode = tempNode;
                [tempNode addRemoveObserver:^{
                    [weakTargetNodeList removeObject:weakTempNode];
                }];
            }
            return YES;
        }
    } else {
        NSLog(@"try to as next: %@", target.node.title);
        if ([target.node addNodeAsNextSibling:tempNode exceptNode:draggingNode]) {
            NSLog(@"add to target node as next: %@", target.node.title);
            if (target.node.parent == self.node) {
                // first level node
                NSMutableArray *targetNodeList = self.leftNodes;
                NSUInteger index = [self.leftNodes indexOfObject:target.node];
                if (index == NSNotFound) {
                    targetNodeList = self.rightNodes;
                    index = [self.rightNodes indexOfObject:target.node];
                }
                if (index == NSNotFound) {
                    NSLog(@"Warning, cannot find node in leftNodes or rightNodes");
                    [tempNode removeFromParent];
                    return NO;
                }
                [targetNodeList insertObject:tempNode atIndex:index + 1];
                __weak typeof(targetNodeList) weakTargetNodeList = targetNodeList;
                __weak typeof(tempNode) weakTempNode = tempNode;
                [tempNode addRemoveObserver:^{
                    [weakTargetNodeList removeObject:weakTempNode];
                }];
            }
            return YES;
        }
    }
    
    return NO;
}

- (NSTextAlignment)textAlignmentForNode:(TSNode *)node textSize:(CGSize)textSize nodeStyle:(id<TSNodeStyle>)nodeStyle originalAlignment:(NSTextAlignment)originalAlignment {
    if ([node isPreferedStyleSetWithAttribute:@"alignment"]) {
        return originalAlignment;
    }
    if (textSize.width < nodeStyle.minWidth) {
        return NSTextAlignmentCenter;
    } else {
        return NSTextAlignmentLeft;
    }
}

@end
