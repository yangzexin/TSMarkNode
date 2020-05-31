//
//  TSConnectionView.h
//  Markdown
//
//  Created by yangzexin on 2020/5/14.
//  Copyright © 2020 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SFiOSKit/SFiOSKit.h>
#import "TSMindView.h"

@class TSLayoutResult;

NS_ASSUME_NONNULL_BEGIN

@interface TSSimpleConnectionView : SFIBCompatibleView <TSMindConnectionView>

@property (nonatomic, weak) TSMindView *mindView;

@property (nonatomic, copy) NSString *lineDash;

@property (nonatomic, assign) NSUInteger lineWidth;

@property (nonatomic, copy) NSString *lineColor;

@property (nonatomic, copy) NSString *fillColor;

@property (nonatomic, assign) NSUInteger fillWidth;

- (UIBezierPath *)pathForParentResult:(TSLayoutResult *)result subResult:(TSLayoutResult *)subResult;

@end

@interface TSDirectConnectionView : TSSimpleConnectionView

@end

@interface TSCurveConnectionView : TSSimpleConnectionView

@end

@interface TSRectConnectionView : TSSimpleConnectionView

@end

@interface TSLineConnectionView : TSSimpleConnectionView

@end

NS_ASSUME_NONNULL_END
