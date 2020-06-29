//
//  TSConnectionView.m
//  TSMarkNode
//
//  Created by yangzexin on 2020/5/14.
//  Copyright © 2020 yangzexin. All rights reserved.
//

#import "TSConnectionView.h"
#import "TSLayouter.h"
#import "TSNode.h"
#import "TSNode+LayoutAddition.h"

@interface TSSimpleConnectionView ()

@property (nonatomic, strong) UIColor *fillColor_;

@end

@implementation TSSimpleConnectionView

+ (Class)layerClass {
    return [CAShapeLayer class];
}

- (void)initCompat {
    [super initCompat];
    CAShapeLayer *shapeLayer = (CAShapeLayer *) self.layer;
    shapeLayer.fillColor = [UIColor clearColor].CGColor;
    shapeLayer.strokeColor = [UIColor blackColor].CGColor;
    shapeLayer.lineWidth = 1.0f;
    [self initShapeLayer:shapeLayer];
    
    __weak typeof(shapeLayer) weakShapeLayer = shapeLayer;
    [SFObserveProperty(self, lineDash) onChange:^(NSString *value) {
        __strong typeof(weakShapeLayer) shapeLayer = weakShapeLayer;
        NSArray *attrs = [value componentsSeparatedByString:@","];
        NSMutableArray<NSNumber *> *lineDash = [NSMutableArray new];
        for (NSString *attr in attrs) {
            NSString *trimedAttr = [attr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            [lineDash addObject:@([trimedAttr integerValue])];
        }
        shapeLayer.lineDashPattern = lineDash;
    }];
    __weak typeof(self) weakSelf = self;
    [SFObserveProperty(self, lineWidth) onChange:^(NSNumber *value) {
        __strong typeof(weakShapeLayer) shapeLayer = weakShapeLayer;
        __strong typeof(weakSelf) self = weakSelf;
        shapeLayer.lineWidth = self.lineWidth;
        shapeLayer.lineCap = kCALineCapRound;
    }];
    [SFObserveProperty(self, lineColor) onChange:^(NSString *value) {
        __strong typeof(weakShapeLayer) shapeLayer = weakShapeLayer;
        shapeLayer.strokeColor = [NSString colorWithAttrValue:value].CGColor;
    }];
    [SFObserveProperty(self, fillColor) onChange:^(NSString *value) {
        __strong typeof(weakSelf) self = weakSelf;
        self.fillColor_ = [NSString colorWithAttrValue:value];
    }];
}

- (void)initShapeLayer:(CAShapeLayer *)shapeLayer {
    
}

- (UIBezierPath *)pathForParentResult:(TSNodeLayoutResult *)result subResult:(TSNodeLayoutResult *)subResult {
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGPoint fromPoint = result.connectionPoint;
    [path moveToPoint:fromPoint];
    CGPoint toPoint = subResult.plugPoint;
    CGPoint controlPoint;
    CGPoint retPoint = fromPoint;
    CGFloat retSize = self.fillWidth;
    CGFloat offset = retSize;
    CGFloat additionWidth = 0;
    if (toPoint.x < fromPoint.x) {
        controlPoint.x = toPoint.x + (fromPoint.x - toPoint.x);
        retPoint.x -= retSize;
        offset = -offset;
        additionWidth = -additionWidth;
    } else {
        controlPoint.x = toPoint.x - (toPoint.x - fromPoint.x);
        retPoint.x += retSize;
    }
    if (toPoint.y < fromPoint.y) {
        controlPoint.y = toPoint.y;
    } else {
        controlPoint.y = toPoint.y;
    }
    
    [path addQuadCurveToPoint:CGPointMake(toPoint.x + additionWidth, toPoint.y) controlPoint:controlPoint];
    if (retSize > 0) {
        if (retPoint.y == toPoint.y) {
            retPoint.y += retSize;
        }
        [path addQuadCurveToPoint:retPoint controlPoint:CGPointMake(controlPoint.x + offset, controlPoint.y)];
        [path addLineToPoint:fromPoint];
    }
    
    return path;
}

- (void)setParentResult:(TSNodeLayoutResult *)result subResult:(TSNodeLayoutResult *)subResult animated:(BOOL)animated {
    CAShapeLayer *shapeLayer = (CAShapeLayer *) self.layer;
    
    UIBezierPath *path = [self pathForParentResult:result subResult:subResult];
    
    if (shapeLayer.path == nil) {
        shapeLayer.path = [UIBezierPath bezierPath].CGPath;
    }
    
    if (animated) {
        CABasicAnimation *animation = [[CABasicAnimation alloc] init];
        animation.keyPath = @"path";
        animation.toValue = (id) path.CGPath;
        animation.duration = .25f;
        animation.removedOnCompletion = NO;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        animation.fillMode = kCAFillModeForwards;
        animation.delegate = [SFAnimationDelegateProxy proxyWithDidStart:nil didFinish:^(BOOL finish) {
            shapeLayer.path = path.CGPath;
            [shapeLayer removeAnimationForKey:@"pathAnimation"];
        }];
        [shapeLayer removeAnimationForKey:@"pathAnimation"];
        [shapeLayer addAnimation:animation forKey:@"pathAnimation"];
    } else {
        shapeLayer.path = path.CGPath;
    }
    if (self.fillColor) {
        shapeLayer.fillColor = self.fillColor_.CGColor;
    } else {
        shapeLayer.fillColor = [UIColor clearColor].CGColor;
    }
}

@end

@implementation TSDirectConnectionView

- (UIBezierPath *)pathForParentResult:(TSNodeLayoutResult *)result subResult:(TSNodeLayoutResult *)subResult {
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGPoint fromPoint = result.connectionPoint;
    [path moveToPoint:fromPoint];
    CGPoint toPoint = subResult.plugPoint;
    [path addLineToPoint:toPoint];
    
    return path;
}

@end

@implementation TSCurveConnectionView

- (UIBezierPath *)pathForParentResult:(TSNodeLayoutResult *)result subResult:(TSNodeLayoutResult *)subResult {
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGPoint fromPoint = result.connectionPoint;
    [path moveToPoint:fromPoint];
    CGPoint toPoint = subResult.plugPoint;
    CGPoint controlPoint2;
    if (toPoint.x < fromPoint.x) {
        // left
        controlPoint2.x = fromPoint.x - result.frame.size.width / 2;
    } else {
        // right
        controlPoint2.x = fromPoint.x + result.frame.size.width / 2;
    }
    if (toPoint.y < fromPoint.y) {
        controlPoint2.y = toPoint.y;
    } else {
        controlPoint2.y = toPoint.y;
    }
    CGPoint controlPoint1 = CGPointMake(toPoint.x, fromPoint.y);
    
    [path addCurveToPoint:toPoint controlPoint1:controlPoint1 controlPoint2:controlPoint2];
    
    return path;
}

- (void)initShapeLayer:(CAShapeLayer *)shapeLayer {
    shapeLayer.lineWidth = 1.0f;
//    shapeLayer.lineDashPattern = @[@5, @5];
}

@end

@implementation TSRectConnectionView

- (UIBezierPath *)pathForParentResult:(TSNodeLayoutResult *)result subResult:(TSNodeLayoutResult *)subResult {
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGPoint fromPoint = result.connectionPoint;
    CGPoint toPoint = subResult.plugPoint;
    
    [path moveToPoint:fromPoint];
    
    CGPoint currentPoint;
    if (fromPoint.x > toPoint.x) {
        // left
        currentPoint = CGPointMake(toPoint.x + (fromPoint.x - toPoint.x - result.frame.size.width / 2) / 2, fromPoint.y);
    } else {
        // right
        currentPoint = CGPointMake(toPoint.x - (toPoint.x - fromPoint.x - result.frame.size.width / 2) / 2, fromPoint.y);
    }
    [path addLineToPoint:currentPoint];
    
    currentPoint = CGPointMake(currentPoint.x, toPoint.y);
    [path addLineToPoint:currentPoint];
    [path addLineToPoint:toPoint];
    
    return path;
}

@end

@implementation TSLineConnectionView

- (void)initCompat {
    [super initCompat];
}

- (UIBezierPath *)pathForParentResult:(TSNodeLayoutResult *)result subResult:(TSNodeLayoutResult *)subResult {
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    CGPoint fromPoint = result.connectionPoint;
    CGPoint toPoint = subResult.plugPoint;
    CGPoint controlPoint2;
    CGFloat additionLineWidth = subResult.displayRect.size.width;
    if (toPoint.x < fromPoint.x) {
        // left
        //fromPoint.x = result.frame.origin.x;
        controlPoint2.x = fromPoint.x - result.frame.size.width / 2;
        additionLineWidth = -additionLineWidth;
    } else {
        // right
        //fromPoint.x = result.frame.origin.x + result.frame.size.width;
        controlPoint2.x = fromPoint.x + result.frame.size.width / 2;
    }
    if (toPoint.y < fromPoint.y) {
        controlPoint2.y = toPoint.y;
    } else {
        controlPoint2.y = toPoint.y;
    }
    [path moveToPoint:fromPoint];
    CGPoint controlPoint1 = CGPointMake(toPoint.x, fromPoint.y);
    
    [path addCurveToPoint:CGPointMake(toPoint.x, toPoint.y + self.lineWidth) controlPoint1:controlPoint1 controlPoint2:controlPoint2];
    [path addLineToPoint:CGPointMake(toPoint.x + additionLineWidth, toPoint.y + self.lineWidth)];
    
    return path;
}

@end
