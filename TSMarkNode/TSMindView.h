//
//  TSMindView.h
//  Markdown
//
//  Created by yangzexin on 2020/5/14.
//  Copyright © 2020 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SFiOSKit/SFiOSKit.h>
#import "TSNodeStyle.h"
#import "TSLayouter.h"
#import "TSNodeSelection.h"

@class TSNode;
@class TSMindView;
@class TSLayoutResult;
@protocol TSMindNodeView;

NS_ASSUME_NONNULL_BEGIN

@protocol TSMindNodeViewDelegate <NSObject>

@optional
- (NSNumber *)mindNodeView:(UIView<TSMindNodeView> *)mindNodeView textAlignmentForNode:(TSNode *)node textSize:(CGSize)textSize style:(id<TSNodeStyle>)style originalAlignment:(NSTextAlignment)originalAlignment;
- (void)mindNodeView:(UIView<TSMindNodeView> *)mindNodeView willChangeNode:(TSNode *)node text:(NSString *)text;
- (void)mindNodeView:(UIView<TSMindNodeView> *)mindNodeView finishEditingNode:(TSNode *)node text:(NSString *)text;

@end

@protocol TSMindNodeView <NSObject>

@property (nonatomic, strong, nullable) TSNode *node;
@property (nonatomic, weak) id<TSMindNodeViewDelegate> delegate;
@property (nonatomic, assign) BOOL dragStateDisplayable;
@property (nonatomic, assign) BOOL editing;
@property (nonatomic, assign) BOOL selected;
@property (nonatomic, assign) CGRect displayRect;
@property (nonatomic, assign) CGRect titleFrame;

@property (nonatomic, strong) id<TSNodeStyle> style;

- (void)widthToFit;
- (CGRect)visibleRect;

@end

@protocol TSMindConnectionView <NSObject>

@property (nonatomic, weak) TSMindView *mindView;

- (void)setParentResult:(TSLayoutResult *)result subResult:(TSLayoutResult *)subResult animated:(BOOL)animated;

@end

@interface TSUpdateSizeHandle : NSObject

@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) BOOL didUpdate;

@end

@protocol TSMindViewDelegate <NSObject>

@optional
- (Class)mindView:(TSMindView *)mindView viewClassForNode:(TSNode *)node;
- (Class)mindView:(TSMindView *)mindView connectionViewClassForNode:(TSNode *)node;

- (void)mindView:(TSMindView *)mindView initView:(UIView<TSMindNodeView> *)view node:(TSNode *)node;
- (void)mindView:(TSMindView *)mindView initConnectionView:(UIView<TSMindConnectionView> *)connectionView node:(TSNode *)node;
- (void)mindView:(TSMindView *)mindView didSelectView:(UIView<TSMindNodeView> *)view;
- (void)mindView:(TSMindView *)mindView triggerActionForView:(UIView<TSMindNodeView> *)view;
- (void)mindView:(TSMindView *)mindView didLayoutView:(UIView<TSMindNodeView> *)view;
- (void)didFinishLayoutMindView:(TSMindView *)mindView;
- (BOOL)mindView:(TSMindView *)mindView draggingToShowRect:(CGRect)rect delta:(CGPoint)delta;
- (void)mindView:(TSMindView *)mindView didUpdateSize:(TSUpdateSizeHandle *)handle;

@end

@interface TSMindView : SFIBCompatibleView <TSLayouterDelegate>

@property (nonatomic, weak) id<TSMindViewDelegate> delegate;

@property (nonatomic, strong) id<TSLayouter> layouter;

@property (nonatomic, strong) TSNode *node;

@property (nonatomic, weak, nullable) TSNode *selectedNode;

@property (nonatomic, strong) id<TSMindViewStyle> style;

- (void)setNode:(TSNode * _Nonnull)node animated:(BOOL)animated;

- (void)setEditing:(BOOL)editing node:(TSNode *)node;

- (nullable TSNodeSelection *)selectionForNode:(TSNode *)node;

- (CGRect)visibleRect;

- (void)removeNode:(TSNode *)node animated:(BOOL)animated;

- (void)refreshAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
