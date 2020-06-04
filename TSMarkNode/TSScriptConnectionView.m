//
//  TSScriptConnectionView.m
//  Markdown
//
//  Created by yangzexin on 2020/5/19.
//  Copyright © 2020 yangzexin. All rights reserved.
//

#import "TSScriptConnectionView.h"
#import "TSScriptMindViewStyle.h"
#import "TSLayouter.h"

@interface TSScriptShape : NSObject

@property (nonatomic, copy) NSString *type;
@property (nonatomic, assign) CGFloat x;
@property (nonatomic, assign) CGFloat y;

@property (nonatomic, assign) CGFloat controlPoint1X;
@property (nonatomic, assign) CGFloat controlPoint1Y;
@property (nonatomic, assign) CGFloat controlPoint2X;
@property (nonatomic, assign) CGFloat controlPoint2Y;

@property (nonatomic, assign) CGFloat arcCenterX;
@property (nonatomic, assign) CGFloat arcCenterY;
@property (nonatomic, assign) CGFloat arcRadius;
@property (nonatomic, assign) CGFloat arcStartAngle;
@property (nonatomic, assign) CGFloat arcEndAngle;
@property (nonatomic, assign) BOOL arcClockwise;

@end

@implementation TSScriptShape

@end

@interface TSScriptDraw : NSObject

@property (nonatomic, strong) NSArray<TSScriptShape *> *shapes;

@end

@implementation TSScriptDraw

@end

@interface TSScriptConnectionView ()

@property (nonatomic, strong) TSLuaEngine *luaEngine;

@end

@implementation TSScriptConnectionView

- (NSDictionary *)_dictionaryForLayoutResult:(TSNodeLayoutResult *)result point:(CGPoint)point {
    return @{@"x": [NSNumber numberWithDouble:point.x],
             @"y": [NSNumber numberWithDouble:point.y],
             @"width": [NSNumber numberWithDouble:result.frame.size.width],
             @"height": [NSNumber numberWithDouble:result.frame.size.height],
             @"displayWidth": [NSNumber numberWithDouble:result.displayRect.size.width],
             @"displayHeight": [NSNumber numberWithDouble:result.displayRect.size.height],
             @"displayX": [NSNumber numberWithDouble:result.displayRect.origin.x],
             @"displayY": [NSNumber numberWithDouble:result.displayRect.origin.y]
             };
}

- (UIBezierPath *)pathForParentResult:(TSNodeLayoutResult *)result subResult:(TSNodeLayoutResult *)subResult {
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"action"] = @"drawConnection";
    params[@"layouterName"] = [self.mindView.layouter name];
    params[@"type"] = self.type;
    params[@"from"] = [self _dictionaryForLayoutResult:result point:result.connectionPoint];
    params[@"to"] = [self _dictionaryForLayoutResult:subResult point:subResult.plugPoint];
    
    __block NSDictionary *resultDict = nil;
    if (self.luaEngine == nil) {
        self.luaEngine = [TSLuaEngine engineByFindingWithId:self.engineId];
        NSAssert(self.luaEngine != nil, @"Cannot find lua engine with id: %ld", self.engineId);
    }
    [self sf_sendServant:[self.luaEngine luaServiceWithName:@"Theme" params:params] success:^(NSString *value) {
        resultDict = [NSJSONSerialization JSONObjectWithData:[value dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    } error:^(NSError *error) {
        NSLog(@"Error on drawing connection view: %@", error);
    }];
    id mapping = SFBeginPropertyMappingWithClass(TSScriptDraw)
        SFMappingPropertyToClass(shapes, TSScriptShape)
    SFEndPropertyMapping;
    TSScriptDraw *draw = [TSScriptDraw sf_objectFromDictionary:resultDict mapping:mapping];
    for (TSScriptShape *shape in draw.shapes) {
        if ([shape.type isEqualToString:@"moveTo"]) {
            [path moveToPoint:CGPointMake(shape.x, shape.y)];
        } else if ([shape.type isEqualToString:@"lineTo"]) {
            [path addLineToPoint:CGPointMake(shape.x, shape.y)];
        } else if ([shape.type isEqualToString:@"quadCurveTo"]) {
            [path addQuadCurveToPoint:CGPointMake(shape.x, shape.y) controlPoint:CGPointMake(shape.controlPoint1X, shape.controlPoint1Y)];
        } else if ([shape.type isEqualToString:@"curveTo"]) {
            [path addCurveToPoint:CGPointMake(shape.x, shape.y) controlPoint1:CGPointMake(shape.controlPoint1X, shape.controlPoint1Y) controlPoint2:CGPointMake(shape.controlPoint2X, shape.controlPoint2Y)];
        } else if ([shape.type isEqualToString:@"arcTo"]) {
            [path addArcWithCenter:CGPointMake(shape.arcCenterX, shape.arcCenterY) radius:shape.arcRadius startAngle:shape.arcStartAngle endAngle:shape.arcEndAngle clockwise:shape.arcClockwise];
        }
    }
    
    return path;
}

@end
