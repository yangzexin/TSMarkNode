//
//  TSNodeStyle.m
//  TSMarkNode
//
//  Created by yangzexin on 2020/5/18.
//  Copyright © 2020 yangzexin. All rights reserved.
//

#import "TSNodeStyle.h"
#import "TSNode+LayoutAddition.h"
#import "TSNodeView.h"
#import "TSConnectionView.h"
#import "TSLayouter.h"

@implementation TSMutableNodeStyle

- (id)init {
    self = [super init];
    
    self.backgroundColor = [UIColor darkGrayColor];
    self.textColor = [UIColor whiteColor];
    self.borderColor = [UIColor darkGrayColor];
    self.borderWidth = 2.0f;
    self.cornerRadius = 10.0f;
    self.maxWidth = 220.0f;
    self.minWidth = 0.0f;
    self.fontSize = 18.0f;
    self.padding = 10.0f;
    self.alignment = TSNodeContentAlignmentCenter;
    self.subAlignment = TSNodeSubAlignmentCenter;
    self.verticalSpacing = 40.0f;
    self.horizontalSpacing = 70.0f;
    self.viewClassName = NSStringFromClass([TSNodeView class]);
    self.connectionViewClassName = NSStringFromClass([TSSimpleConnectionView class]);
    self.connectionViewAttributes = nil;
    
    return self;
}

- (id)initWithStyle:(id<TSNodeStyle>)style {
    self = [super init];
    
    [self setWithStyle:style];
    
    return self;
}

- (void)setWithStyle:(id<TSNodeStyle>)style {
    [[self class] setFromStyle:style toStyle:self];
}

+ (void)setFromStyle:(id<TSNodeStyle>)fromStyle toStyle:(TSMutableNodeStyle *)toStyle {
    toStyle.backgroundColor = [fromStyle.backgroundColor copy];
    toStyle.textColor = [fromStyle.textColor copy];
    toStyle.borderColor = [fromStyle.borderColor copy];
    toStyle.borderWidth = fromStyle.borderWidth;
    toStyle.cornerRadius = fromStyle.cornerRadius;
    toStyle.maxWidth = fromStyle.maxWidth;
    toStyle.minWidth = fromStyle.minWidth;
    toStyle.fontSize = fromStyle.fontSize;
    toStyle.padding = fromStyle.padding;
    toStyle.alignment = fromStyle.alignment;
    toStyle.subAlignment = fromStyle.subAlignment;
    toStyle.verticalSpacing = fromStyle.verticalSpacing;
    toStyle.horizontalSpacing = fromStyle.horizontalSpacing;
    toStyle.viewClassName = [fromStyle.viewClassName copy];
    toStyle.connectionViewClassName = [fromStyle.connectionViewClassName copy];
    toStyle.connectionViewAttributes = [fromStyle.connectionViewAttributes copy];
}

- (id)mutableCopyWithZone:(nullable NSZone *)zone {
    TSMutableNodeStyle *style = [[self class] allocWithZone:zone];
    [[self class] setFromStyle:self toStyle:style];
    
    return style;
}

@end

@interface TSPreferedNodeStyle ()

@property (nonatomic, strong) NSMutableSet *attrSet;

@end

@implementation TSPreferedNodeStyle

- (id)init {
    self = [super init];
    
    self.attrSet = [NSMutableSet set];
    
    return self;
}

- (void)setAttributeHasVaue:(NSString *)attr {
    [_attrSet addObject:attr];
}

- (BOOL)isAttributeHasValue:(NSString *)attr {
    return [_attrSet containsObject:attr];
}

- (BOOL)empty {
    return [_attrSet count] == 0;
}

- (NSSet *)attributeSet {
    return [_attrSet copy];
}

@end

@interface TSDefaultMindViewStyle () <TSNodeStyle>

@property (nonatomic, strong) TSMutableNodeStyle *rootNodeStyle;
@property (nonatomic, strong) TSMutableNodeStyle *level1Style;
@property (nonatomic, strong) TSMutableNodeStyle *otherStyle;

@end

@implementation TSDefaultMindViewStyle

+ (instancetype)shared {
    static TSDefaultMindViewStyle *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [TSDefaultMindViewStyle new];
    });
    
    return instance;
}

- (id)init {
    self = [super init];
    
    self.rootNodeStyle = [TSMutableNodeStyle new];
    self.rootNodeStyle.borderWidth = 2.0f;
    self.rootNodeStyle.backgroundColor = [UIColor orangeColor];
    self.rootNodeStyle.fontSize = 27.0f;
    self.rootNodeStyle.connectionViewClassName = NSStringFromClass([TSSimpleConnectionView class]);
    
    self.level1Style = [TSMutableNodeStyle new];
    self.level1Style.borderWidth = 1.0f;
    self.level1Style.fontSize = 22.0f;
    self.level1Style.connectionViewClassName = NSStringFromClass([TSCurveConnectionView class]);
    self.level1Style.backgroundColor = [UIColor darkGrayColor];
    self.level1Style.textColor = [UIColor whiteColor];
    
    self.otherStyle = [TSMutableNodeStyle new];
    self.otherStyle.borderWidth = .0f;
    self.otherStyle.fontSize = 16.0f;
    self.otherStyle.subAlignment = TSNodeSubAlignmentCenter;
    self.otherStyle.connectionViewClassName = NSStringFromClass([TSLineConnectionView class]);
    self.otherStyle.viewClassName = NSStringFromClass([TSSimpleNodeView class]);
    self.otherStyle.backgroundColor = [UIColor sf_colorWithRed:255 green:255 blue:255 alpha:100];
    self.otherStyle.alignment = TSNodeContentAlignmentLeft;
    self.otherStyle.textColor = [UIColor blackColor];
    
    return self;
}

- (void)willLayoutRootNode:(nullable TSNode *)node layouterName:(nonnull NSString *)layouterName {
    [self _setNodeDisplayLevel:node displayLevel:0];
}

- (void)_setNodeDisplayLevel:(TSNode *)node displayLevel:(NSUInteger)displayLevel {
    node.displayLevel = @(displayLevel);
    for (TSNode *subNode in node.subnodes) {
        [self _setNodeDisplayLevel:subNode displayLevel:displayLevel + 1];
    }
}

- (id<TSNodeStyle>)styleForNode:(nullable TSNode *)node {
    if (node == nil || [node isRootNode]) {
        return self.rootNodeStyle;
    }
    NSNumber *displayLevelNumber = node.displayLevel;
    if (displayLevelNumber) {
        NSUInteger displayLevel = displayLevelNumber.unsignedIntValue;
        if (displayLevel == 1) {
            return self.level1Style;
        } else {
            return self.otherStyle;
        }
    }
    
    return self;
}

@end
