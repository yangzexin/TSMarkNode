//
//  TSNodeView.h
//  Markdown
//
//  Created by yangzexin on 2020/5/14.
//  Copyright © 2020 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <SFiOSKit/SFiOSKit.h>
#import "TSLayouter.h"
#import "TSMindView.h"

@class TSNode;

NS_ASSUME_NONNULL_BEGIN

@interface TSNodeView : SFIBCompatibleView <TSMindNodeView>

@property (nonatomic, assign) BOOL dragStateDisplayable;

@property (nonatomic, assign) BOOL editing;
@property (nonatomic, assign) BOOL selected;
@property (nonatomic, assign) CGRect displayRect;
@property (nonatomic, assign) CGRect titleFrame;

@property (nonatomic, weak) id<TSMindNodeViewDelegate> delegate;
@property (nonatomic, strong) TSNode *node;

@property (nonatomic, strong) id<TSNodeStyle> style;

- (void)widthToFit;

- (CGRect)visibleRect;

@end

@interface TSSimpleNodeView : TSNodeView

@end

NS_ASSUME_NONNULL_END
