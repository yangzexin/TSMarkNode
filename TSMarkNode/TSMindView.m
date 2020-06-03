//
//  TSMindView.m
//  Markdown
//
//  Created by yangzexin on 2020/5/14.
//  Copyright © 2020 yangzexin. All rights reserved.
//

#import "TSMindView.h"
#import "TSNode.h"
#import "TSNodeSelection.h"
#import "TSNode+LayoutAddition.h"
#import "TSConnectionView.h"
#import "TSStandardLayouter.h"

@implementation TSUpdateSizeHandle

@end

@interface TSNodeLayoutContext : NSObject

@property (nonatomic, weak) UIView<TSMindNodeView> *nodeView;
@property (nonatomic, weak) UIView<TSMindConnectionView> *connectionView;

@end

@implementation TSNodeLayoutContext

@end

@interface TSViewFrameChangeContext : NSObject

@property (nonatomic, copy) void(^doChange)(void);

@end

@implementation TSViewFrameChangeContext

@end

@interface TSMindView () <TSMindNodeViewDelegate>

@property (nonatomic, strong) UIView *connectionViewContainer;
@property (nonatomic, strong) UIView *nodeViewContainer;

@property (nonatomic, strong) TSLayoutResult *layoutResult;

@property (nonatomic, strong) NSMutableArray<TSViewFrameChangeContext *> *changeContextList;

@property (nonatomic, assign) BOOL animating;
@property (nonatomic, assign) BOOL layoutFlag;
@property (nonatomic, assign) BOOL dragging;

@property (nonatomic, strong) TSNodeSelection *draggingNodeSelection;
@property (nonatomic, strong) UIView<TSMindNodeView> *draggingNodeView;
@property (nonatomic, assign) CGPoint lastDragPosition;
@property (nonatomic, assign) CGPoint dragTempNodeGenPosition;
@property (nonatomic, strong) TSNode *draggingTempAddNode;
@property (nonatomic, strong) TSNode *draggingNodeParent;
@property (nonatomic, assign) NSUInteger draggingNodeSubIndex;

@property (nonatomic, weak) UIView<TSMindNodeView> *lastSelectNodeView;

@end

@implementation TSMindView

- (void)initCompat {
    [super initCompat];
    self.animating = NO;
    self.layoutFlag = YES;
    self.dragging = NO;
    self.style = [TSDefaultMindViewStyle shared];
    
    self.layouter = ({
        TSStandardLayouter *layouter = [[TSStandardLayouter alloc] init];
        layouter.delegate = self;
        layouter;
    });
    
    __weak typeof(self) weakSelf = self;
    [SFTrackProperty(self, node) onChange:^(id value) {
        __strong typeof(self) self = weakSelf;
        
        [self.node setRootNode:YES];
        [self _updateLayoutResults];
    }];
    
    [self sf_addTapListener:^(UITapGestureRecognizer *gr){
        __strong typeof(self) self = weakSelf;
        CGPoint point = [gr locationInView:gr.view];
        [self _tapAtPoint:point];
    }];
    
    [SFObserveProperty(self, selectedNode) onChange:^(id value) {
        __strong typeof(self) self = weakSelf;
        if (self.selectedNode) {
            if (self.lastSelectNodeView) {
                self.lastSelectNodeView.selected = NO;
            }
            self.lastSelectNodeView = [self.selectedNode.context nodeView];
            self.lastSelectNodeView.selected = YES;
        } else {
            self.lastSelectNodeView.selected = NO;
        }
    }];
    
    [SFTrackProperty(self, style) onChange:^(id value) {
        __strong typeof(self) self = weakSelf;
        [self _initContainerViews];
    }];
    
    [SFObserveProperty(self, layouter) onChange:^(id value) {
        __strong typeof(self) self = weakSelf;
        self.layouter.delegate = self;
        [self _initContainerViews];
    }];
    
    UILongPressGestureRecognizer *longPressGR = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_longPressGestureRecognizerAction:)];
    longPressGR.minimumPressDuration = 1.0f;
    longPressGR.allowableMovement = 100.0f;
    [self addGestureRecognizer:longPressGR];
}

- (void)_initContainerViews {
    if (!self.connectionViewContainer) {
        self.connectionViewContainer = ({
            UIView *view = [[UIView alloc] initWithFrame:self.bounds];
            view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self addSubview:view];
            view;
        });
    } else {
        [self.connectionViewContainer sf_removeAllSubviews];
    }
    if (!self.nodeViewContainer) {
        self.nodeViewContainer = ({
            UIView *view = [[UIView alloc] initWithFrame:self.bounds];
            view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            view.backgroundColor = [UIColor clearColor];
            [self addSubview:view];
            view;
        });
    } else {
        [self.nodeViewContainer sf_removeAllSubviews];
    }
    if (self.node) {
        [TSNode traverseNode:self.node block:^(TSNode * _Nonnull node) {
            node.context = nil;
        }];
        [self _updateLayoutResults];
        [self layoutWithAnimated:NO];
    }
}

- (void)_initDraggingNodeViewWithNode:(TSNode *)node frame:(CGRect)frame {
    CGRect initialFrame = frame;
    if (_draggingNodeView == nil) {
        _draggingNodeView = [self _createNodeView:node style:node.style frame:initialFrame];
        _draggingNodeView.displayRect = CGRectMake(0, 0, frame.size.width, frame.size.height);
        _draggingNodeView.dragStateDisplayable = NO;
        [self addSubview:_draggingNodeView];
    }
    [self _initNodeView:_draggingNodeView node:node];
    _draggingNodeView.frame = initialFrame;
    _draggingNodeView.titleFrame = [[node context] nodeView].titleFrame;
    _draggingNodeView.node = node;
    [_draggingNodeView widthToFit];
    [UIView animateWithDuration:0.10f animations:^{
        CGRect frame = self.draggingNodeView.frame;
        frame.origin.x -= 40;
        frame.origin.y -= 40;
        self.draggingNodeView.frame = frame;
    }];
}

- (void)_updateLayoutResults {
    id<TSMindViewStyle> mindViewStyle = self.style;
    BOOL usePreferedStyle = NO;
    if ([self.layouter respondsToSelector:@selector(preferedMindViewStyle)]) {
        id<TSMindViewStyle> preferedStyle = [self.layouter preferedMindViewStyle];
        if (preferedStyle != nil) {
            mindViewStyle = preferedStyle;
            usePreferedStyle = YES;
        }
    }
    [mindViewStyle willLayoutRootNode:self.node layouterName:self.layouter.name];
    
    [TSNode traverseNode:self.node block:^(TSNode * _Nonnull node) {
        id<TSNodeStyle> style = [mindViewStyle styleForNode:node];
        if (usePreferedStyle) {
            [node setStyle:style];
        } else {
            id<TSNodeStyle> wrappedStyle = [node styleByWrappingWithPreferedStyle:style];
            [node setStyle:wrappedStyle];
        }
    }];
    self.layoutResult = [self.layouter layout:self.node size:self.bounds.size];
    CGSize visibleSize = [self visibleRect].size;
    CGSize currentSize = self.bounds.size;
    if (visibleSize.width > currentSize.width || visibleSize.height > currentSize.height) {
        if ([self.delegate respondsToSelector:@selector(mindView:didUpdateSize:)]) {
            TSUpdateSizeHandle *handle = [TSUpdateSizeHandle new];
            handle.size = visibleSize;
            handle.didUpdate = NO;
            [self.delegate mindView:self didUpdateSize:handle];
            if (handle.didUpdate) {
                self.layoutResult = [self.layouter layout:self.node size:self.bounds.size];
            }
        }
    }
    
    if (self.layoutFlag) {
        [self layoutWithAnimated:NO];
    }
}

- (void)_setDragging:(BOOL)dragging node:(TSNode *)node  {
    [TSNode traverseNode:node block:^(TSNode * _Nonnull node) {
        [node setDragging:dragging];
    }];
}

- (void)_longPressGestureRecognizerAction:(UILongPressGestureRecognizer *)gr {
    if (gr.state == UIGestureRecognizerStateBegan) {
        if (![self.layouter shouldStartDragging]) {
            return;
        }
        CGPoint point = [gr locationInView:gr.view];
        TSNodeSelection *nodeSelection = [self selectionWithPoint:point];
        if (nodeSelection && nodeSelection.node != self.node) {
            if ([self.delegate respondsToSelector:@selector(mindView:triggerActionForView:)]) {
                [self.delegate mindView:self triggerActionForView:nodeSelection.context];
            }
            self.selectedNode = nil;
            [self _setDragging:YES node:nodeSelection.node];
            
            self.draggingNodeSelection = nodeSelection;
            self.draggingNodeParent = self.draggingNodeSelection.node.parent;
            self.draggingNodeSubIndex = [self.draggingNodeSelection.node removeFromParent];
            
            [self _initDraggingNodeViewWithNode:self.draggingNodeSelection.node frame:self.draggingNodeSelection.frame];
            self.draggingNodeView.alpha = .72f;
            self.draggingNodeView.hidden = NO;
            [self _refreshUsingCurrentNodeAnimated:NO];
            self.lastDragPosition = point;
        }
    } else if (gr.state == UIGestureRecognizerStateEnded || gr.state == UIGestureRecognizerStateCancelled) {
        void(^completion)(BOOL) = ^(BOOL restoreDraggingNode){
            [self _setDragging:NO node:self.draggingNodeSelection.node];
            if (restoreDraggingNode) {
                if (self.draggingTempAddNode) {
                    [self.draggingTempAddNode removeFromParent];
                }
                if (self.draggingNodeView.node) {
                    [self.draggingNodeParent addNodeAsSub:self.draggingNodeView.node index:self.draggingNodeSubIndex];
                }
            }
            self.draggingNodeSelection = nil;
            [self.draggingNodeView removeFromSuperview];
            self.draggingNodeView = nil;
            self.draggingTempAddNode = nil;
            [self _refreshUsingCurrentNodeAnimated:NO];
        };
        if (self.draggingTempAddNode == nil) {
            // restore temp removed node
            self.draggingNodeView.dragStateDisplayable = NO;
            [UIView animateWithDuration:0.25f animations:^{
                self.draggingNodeView.frame = self.draggingNodeSelection.frame;
            } completion:^(BOOL finished) {
                completion(YES);
            }];
        } else {
            [TSNode traverseNode:self.draggingTempAddNode block:^(TSNode * _Nonnull node) {
                [node setTempAdd:NO];
            }];
            completion(NO);
        }
    } else if (gr.state == UIGestureRecognizerStateChanged) {
        CGPoint point = [gr locationInView:gr.view];
        CGFloat xDelta = point.x - self.lastDragPosition.x;
        CGFloat yDelta = point.y - self.lastDragPosition.y;
        
        __weak typeof(self) weakSelf = self;
        [self sf_deposit:[SFDelayControl delayWithInterval:0.10f completion:^{
            __strong typeof(self) self = weakSelf;
            CGFloat xDistance = fabs(self.dragTempNodeGenPosition.x - point.x);
            CGFloat yDistance = fabs(self.dragTempNodeGenPosition.y - point.y);
            //NSLog(@"%f, %f", xDistance, yDistance);
            if (xDistance > 1.70f || yDistance > 1.70f) {
                [self _checkDraggingInsertNodeWithPoint:point];
            }
        }] identifier:@"ID_CheckNodePosition"];
        
        CGRect frame = self.draggingNodeView.frame;
        frame.origin.x += xDelta;
        frame.origin.y += yDelta;
        if ([self.delegate respondsToSelector:@selector(mindView:draggingToShowRect:delta:)]) {
            if (![self.delegate mindView:self draggingToShowRect:self.draggingNodeView.frame delta:CGPointMake(fabs(xDelta), fabs(yDelta))]) {
                self.draggingNodeView.frame = frame;
            }
        } else {
            self.draggingNodeView.frame = frame;
        }
        self.lastDragPosition = point;
    }
}

- (void)_checkDraggingInsertNodeWithPoint:(CGPoint)point {
    CGRect draggingFrame = self.draggingNodeView.frame;
    __block TSLayoutResult *targetResult = nil;
    [TSLayoutResult traverseWithResult:self.layoutResult reverse:YES block:^(TSLayoutResult * _Nonnull result, BOOL * _Nonnull stop) {
        if ([result.node isDescendantOfNode:self.draggingNodeView.node]) {
            return;
        }
        CGRect matchingRect = result.frame;
        matchingRect.origin.y -= result.node.style.verticalSpacing / 2;
        matchingRect.size.height += result.node.style.verticalSpacing;
        if (CGRectIntersectsRect(draggingFrame, matchingRect)) {
            *stop = YES;
            targetResult = result;
        }
    }];
    if (targetResult.node == self.draggingTempAddNode) {
        return;
    }
    void(^removeTempNode)(void) = ^{
        if (self.draggingTempAddNode) {
            [self.draggingTempAddNode removeFromParent];
            self.draggingTempAddNode = nil;
            [self _refreshUsingCurrentNodeAnimated:NO];
        }
    };
    if (targetResult == nil) {
        removeTempNode();
        return;
    }
    TSNode *tempNode = [self.draggingNodeView.node copyForDragging];
    CGRect matchingRect = targetResult.frame;
    CGRect displayRect = [[targetResult.node.context nodeView] visibleRect];
    displayRect.origin.x += matchingRect.origin.x;
    displayRect.origin.y += matchingRect.origin.y;
    NSLog(@"dragging close to target node: %@", targetResult.node.title);
    if (![self.layouter shouldPerformDragWithDraggingNode:self.draggingNodeView.node draggingFrame:draggingFrame targetDisplayRect:displayRect closingToTarget:targetResult tempNode:tempNode]) {
        removeTempNode();
        NSLog(@"performing dragging to target node failed: %@", targetResult.node.title);
        return;
    } else {
        NSLog(@"performing dragging to target node : %@", targetResult.node.title);
    }
    
    removeTempNode();
    NSLog(@"temp node parent: %@", tempNode.parent.title);
    if (tempNode.parent != nil) {
        self.draggingTempAddNode = tempNode;
        self.dragTempNodeGenPosition = point;
        
        self.draggingNodeView.alpha = .40f;
        [self _refreshUsingCurrentNodeAnimated:NO];
    }
}

- (void)_refreshUsingCurrentNodeAnimated:(BOOL)animated {
    [self setNode:self.node animated:animated];
}

- (void)refreshAnimated:(BOOL)animated {
    [self _refreshUsingCurrentNodeAnimated:animated];
}

- (void)_tapAtPoint:(CGPoint)point {
    TSNodeSelection *selection = [self selectionWithPoint:point];
    TSNode *targetNode = [selection node];
    UIView<TSMindNodeView> *targetView = [selection context];
    
    if (targetNode) {
        self.selectedNode = targetNode;
    } else {
        self.selectedNode = nil;
    }
    if ([self.delegate respondsToSelector:@selector(mindView:didSelectView:)]) {
        [self.delegate mindView:self didSelectView:targetView];
    }
}

- (void)_initNodeView:(UIView<TSMindNodeView> *)nodeView node:(TSNode *)node {
    if ([self.delegate respondsToSelector:@selector(mindView:initView:node:)]) {
        [self.delegate mindView:self initView:nodeView node:node];
    }
}

- (UIView<TSMindNodeView> *)_createNodeView:(TSNode *)node style:(id<TSNodeStyle>)style frame:(CGRect)frame {
    UIView<TSMindNodeView> *view = nil;
    if ([self.delegate respondsToSelector:@selector(mindView:viewClassForNode:)]) {
        Class viewClass = [self.delegate mindView:self viewClassForNode:node];
        view = [[viewClass alloc] initWithFrame:frame];
    } else {
        Class viewClass = NSClassFromString(style.viewClassName);
        view = [[viewClass alloc] initWithFrame:frame];
    }
    [view setDelegate:self];
    view.style = style;
    view.node = node;
    
    return view;
}

- (TSNodeSelection *)selectionForNodeView:(UIView<TSMindNodeView> *)nodeView {
    TSNodeSelection *selection = [TSNodeSelection new];
    selection.context = nodeView;
    selection.node = [nodeView node];
    CGRect displayRect = [nodeView visibleRect];
    displayRect.origin = CGPointMake(nodeView.frame.origin.x + displayRect.origin.x, nodeView.frame.origin.y + displayRect.origin.y);
    selection.frame = displayRect;
    
    return selection;
}

- (TSNodeSelection *)selectionWithPoint:(CGPoint)point {
    TSNodeSelection *selection = nil;
    
    for (UIView *view in [self.nodeViewContainer subviews]) {
        UIView<TSMindNodeView> *nodeView = (UIView<TSMindNodeView> *) view;
        CGPoint relativePoint = CGPointMake(point.x - view.frame.origin.x, point.y - view.frame.origin.y);
        CGRect visibleRect = nodeView.visibleRect;
        if ([UIView sf_isPointInFrame:visibleRect point:relativePoint]) {
            selection = [self selectionForNodeView:nodeView];
            break;
        }
    }
    
    return selection;
}

- (TSNodeSelection *)selectionForNode:(TSNode *)node {
    TSNodeSelection *selection = nil;
    
    for (UIView *view in [self.nodeViewContainer subviews]) {
        if (![view conformsToProtocol:@protocol(TSMindNodeView)]) {
            continue;
        }
        UIView<TSMindNodeView> *nodeView = (UIView<TSMindNodeView> *) view;
        if (node == nodeView.node) {
            selection = [self selectionForNodeView:nodeView];
            break;
        }
    }
    
    return selection;
}

- (void)setNode:(TSNode * _Nonnull)node animated:(BOOL)animated {
    self.animating = animated;
    BOOL tmpLayoutFlag = self.layoutFlag;
    self.layoutFlag = NO;
    BOOL reinitContainer = self.node != node;
    self.node = node;
    self.layoutFlag = tmpLayoutFlag;
    if (reinitContainer) {
        [self _initContainerViews];
    }
    [self layoutWithAnimated:animated];
    self.animating = NO;
    
    [TSNode traverseNode:self.node block:^(TSNode * _Nonnull node) {
        if (node != self.node && node.parent == nil) {
            NSLog(@"nil parent found: %@, %p", node.title, node);
        }
    }];
}

- (void)_layoutWithResult:(TSLayoutResult *)result {
    TSNodeLayoutContext *context = result.node.context;
    if (context == nil) {
        context = [TSNodeLayoutContext new];
        [result.node setContext:context];
    }
    UIView<TSMindNodeView> *view = context.nodeView;
    id<TSNodeStyle> nodeStyle = result.node.style;
    Class viewClass = NSClassFromString(nodeStyle.viewClassName);
    BOOL selected = NO;
    if (view != nil && view.class  != viewClass) {
        selected = view.selected;
        [view removeFromSuperview];
        view = nil;
    }
    if (view == nil) {
        CGRect initialFrame = result.frame;
        
        view = [self _createNodeView:result.node style:nodeStyle frame:initialFrame];
        __weak typeof(view) weakView = view;
        [view sf_deposit:[result.node addRemoveObserver:^{
            [weakView removeFromSuperview];
        }]];
        context.nodeView = view;
        [self.nodeViewContainer addSubview:view];
        [self _initNodeView:view node:result.node];
        view.displayRect = result.displayRect;
        view.titleFrame = result.titleFrame;
        view.node = result.node;
        if (selected) {
            self.lastSelectNodeView = view;
            view.selected = selected;
        }
    }
    view.style = nodeStyle;
    TSViewFrameChangeContext *changeContext = [TSViewFrameChangeContext new];
    [changeContext setDoChange:^{
        view.frame = result.frame;
        view.displayRect = result.displayRect;
        view.titleFrame = result.titleFrame;
        view.node = result.node;
        [view widthToFit];
    }];
    [self.changeContextList addObject:changeContext];
    
    for (TSLayoutResult *subResult in result.subNodeResults) {
        [self _layoutWithResult:subResult];
        UIView<TSMindConnectionView> *connectionView = [subResult.node.context connectionView];
        id<TSNodeStyle> nodeStyle = result.node.style;
        Class connectionViewClass = NSClassFromString(nodeStyle.connectionViewClassName);
        if (connectionView != nil && connectionView.class != connectionViewClass) {
            [connectionView removeFromSuperview];
            connectionView = nil;
        }
        if (!connectionView) {
            connectionView = [[connectionViewClass alloc] initWithFrame:self.connectionViewContainer.bounds];
            connectionView.mindView = self;
            [subResult.node.context setConnectionView:connectionView];
            if (nodeStyle.connectionViewAttributes != nil) {
                [connectionView sf_setPropertyValuesFromDictionary:nodeStyle.connectionViewAttributes];
            }
            [self.connectionViewContainer addSubview:connectionView];
            __weak typeof(connectionView) weakConnectionView = connectionView;
            [connectionView sf_deposit:[subResult.node addRemoveObserver:^{
                [weakConnectionView removeFromSuperview];
            }]];
        }
        [connectionView setParentResult:result subResult:subResult animated:self.animating];
    }
}

- (void)layoutWithAnimated:(BOOL)animated {
    self.changeContextList = [NSMutableArray array];
    [self _layoutWithResult:self.layoutResult];
    void(^animations)(void) = ^{
        for (TSViewFrameChangeContext *changeContext in self.changeContextList) {
            changeContext.doChange();
        }
    };
    void(^completion)(void) = ^{
        if ([self.delegate respondsToSelector:@selector(didFinishLayoutMindView:)]) {
            [self.delegate didFinishLayoutMindView:self];
        }
    };
    if (animated) {
        [UIView animateWithDuration:0.25f animations:animations completion:^(BOOL finished) {
            completion();
        }];
    } else {
        animations();
        completion();
    }
}

- (CGRect)visibleRect {
    CGRect rect;
    rect.size.width = self.layoutResult.allWidth;
    rect.origin.x = (self.bounds.size.width - self.layoutResult.allWidth) / 2;
    rect.size.height = self.layoutResult.frame.size.height;
    rect.origin.y = (self.bounds.size.height - rect.size.height) / 2;
    
    return rect;
}

- (void)removeNode:(TSNode *)node animated:(BOOL)animated {
    if (self.selectedNode == node) {
        self.selectedNode = nil;
    }
    [node removeFromParent];
    
    [self _refreshUsingCurrentNodeAnimated:animated];
}

- (void)setEditing:(BOOL)editing node:(TSNode *)node {
    UIView<TSMindNodeView> *nodeView = [[node context] nodeView];
    [nodeView setEditing:editing];
}

- (void)mindNodeView:(UIView<TSMindNodeView> *)mindNodeView willChangeNode:(TSNode *)node text:(nonnull NSString *)text {
    node.title = [text copy];
    [self _refreshUsingCurrentNodeAnimated:YES];
}

- (void)mindNodeView:(UIView<TSMindNodeView> *)mindNodeView finishEditingNode:(TSNode *)node text:(nonnull NSString *)text {
    [self setEditing:NO node:node];
    node.title = [text copy];
    [self _refreshUsingCurrentNodeAnimated:YES];
}

- (NSNumber *)mindNodeView:(UIView<TSMindNodeView> *)mindNodeView textAlignmentForNode:(TSNode *)node textSize:(CGSize)textSize style:(id<TSNodeStyle>)style originalAlignment:(NSTextAlignment)originalAlignment {
    if ([self.layouter respondsToSelector:@selector(textAlignmentForNode:textSize:nodeStyle:originalAlignment:)]) {
        NSTextAlignment alignment = [self.layouter textAlignmentForNode:node textSize:textSize nodeStyle:style originalAlignment:originalAlignment];
        return [NSNumber numberWithInteger:alignment];
    }
    return nil;
}

- (TSLimitedSize)layouter:(id<TSLayouter>)layouter limitedSizeForNode:(TSNode *)node {
    TSLimitedSize size = {node.style.maxWidth, node.style.minWidth};
    
    return size;
}

- (UIFont *)layouter:(id<TSLayouter>)layouter fontForNode:(TSNode *)node {
    return [UIFont systemFontOfSize:node.style.fontSize];
}

- (CGFloat)layouter:(id<TSLayouter>)layouter paddingForNode:(TSNode *)node {
    return [node.style padding];
}

- (TSSpacing)layouter:(id<TSLayouter>)layouter spacingForNode:(TSNode *)node {
    TSSpacing spacing = {node.style.verticalSpacing, node.style.horizontalSpacing};
    
    return spacing;
}

- (TSNodeSubAlignment)layouter:(id<TSLayouter>)layouter subAlignmentForNode:(TSNode *)node {
    return node.style.subAlignment;
}

@end
