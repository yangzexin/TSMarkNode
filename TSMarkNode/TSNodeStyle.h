//
//  TSNodeTheme.h
//  Markdown
//
//  Created by yangzexin on 2020/5/18.
//  Copyright © 2020 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TSLuaEngine.h"

@class TSNode;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, TSNodeContentAlignment) {
    TSNodeContentAlignmentCenter = 0,
    TSNodeContentAlignmentLeft = 1,
    TSNodeContentAlignmentRight = 2
};

typedef NS_ENUM(NSUInteger, TSNodeSubAlignment) {
    TSNodeSubAlignmentCenter = 0,
    TSNodeSubAlignmentTop = 1
};

@protocol TSNodeStyle <NSObject>

@property (nonatomic, strong, readonly) UIColor *backgroundColor;
@property (nonatomic, strong, readonly) UIColor *textColor;
@property (nonatomic, strong, readonly) UIColor *borderColor;
@property (nonatomic, assign, readonly) NSUInteger borderWidth;
@property (nonatomic, assign, readonly) NSUInteger cornerRadius;
@property (nonatomic, assign, readonly) NSUInteger maxWidth;
@property (nonatomic, assign, readonly) NSUInteger minWidth;
@property (nonatomic, assign, readonly) NSUInteger fontSize;
@property (nonatomic, assign, readonly) NSUInteger padding;
@property (nonatomic, assign, readonly) NSUInteger alignment;
@property (nonatomic, assign, readonly) NSUInteger subAlignment;
@property (nonatomic, assign, readonly) NSUInteger verticalSpacing;
@property (nonatomic, assign, readonly) NSUInteger horizontalSpacing;

@property (nonatomic, copy, readonly) NSString *viewClassName;
@property (nonatomic, copy, readonly) NSString *connectionViewClassName;
@property (nonatomic, strong, readonly, nullable) NSDictionary *connectionViewAttributes;

@end

@interface TSMutableNodeStyle : NSObject <TSNodeStyle, NSMutableCopying>

@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIColor *borderColor;
@property (nonatomic, assign) NSUInteger borderWidth;
@property (nonatomic, assign) NSUInteger cornerRadius;
@property (nonatomic, assign) NSUInteger maxWidth;
@property (nonatomic, assign) NSUInteger minWidth;
@property (nonatomic, assign) NSUInteger fontSize;
@property (nonatomic, assign) NSUInteger padding;
@property (nonatomic, assign) NSUInteger alignment;
@property (nonatomic, assign) NSUInteger subAlignment;
@property (nonatomic, assign) NSUInteger verticalSpacing;
@property (nonatomic, assign) NSUInteger horizontalSpacing;

@property (nonatomic, copy) NSString *viewClassName;
@property (nonatomic, copy) NSString *connectionViewClassName;
@property (nonatomic, strong, nullable) NSDictionary *connectionViewAttributes;

- (id)initWithStyle:(id<TSNodeStyle>)style;

- (void)setWithStyle:(id<TSNodeStyle>)style;

@end

@interface TSPreferedNodeStyle : TSMutableNodeStyle

- (void)setAttributeHasVaue:(NSString *)attr;
- (BOOL)isAttributeHasValue:(NSString *)attr;
- (BOOL)empty;
- (NSSet *)attributeSet;

@end

@class TSMindView;

@protocol TSMindViewStyle <NSObject>

- (void)willLayoutRootNode:(nullable TSNode *)node layouterName:(NSString *)layouterName;

- (id<TSNodeStyle>)styleForNode:(nullable TSNode *)node;

@end

@interface TSDefaultMindViewStyle : TSMutableNodeStyle <TSMindViewStyle>

+ (instancetype)shared;

@end

NS_ASSUME_NONNULL_END
