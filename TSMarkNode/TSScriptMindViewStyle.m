//
//  TSScriptMindViewTheme.m
//  Markdown
//
//  Created by yangzexin on 2020/5/19.
//  Copyright © 2020 yangzexin. All rights reserved.
//

#import "TSScriptMindViewStyle.h"
#import <SFiOSKit/SFiOSKit.h>
#import "TSNode.h"
#import "TSNode+LayoutAddition.h"

@interface TSScriptNodeStyle : TSMutableNodeStyle

@property (nonatomic, strong) NSArray<TSScriptNodeStyle *> *subnodes;

@end

@implementation TSScriptNodeStyle

@end

@interface TSScriptMindViewStyle ()

@end

@implementation TSScriptMindViewStyle

- (instancetype)initWithEngine:(TSLuaEngine *)engine {
    TSScriptMindViewStyle *style = [TSScriptMindViewStyle new];
    style.luaEngine = engine;
    
    return style;
}

- (void)willLayoutRootNode:(nullable TSNode *)node layouterName:(nonnull NSString *)layouterName {
    NSMutableDictionary *nodeDict = [TSNode dictionaryForNode:node wrapper:^(TSNode * _Nonnull item, NSMutableDictionary * _Nonnull dict) {
        
    }];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"action": @"getStyle"}];
    [params setObject:nodeDict forKey:@"node"];
    [params setObject:layouterName forKey:@"layouterName"];
    __block NSDictionary *resultDict = nil;
    [self sf_sendServant:[self.luaEngine luaServiceWithName:@"Theme" params:params] success:^(id value) {
        resultDict = [NSJSONSerialization JSONObjectWithData:[value dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    } error:^(NSError *error) {
        NSLog(@"Error on getting theme for node: %@", node.title);
    }];
    id mapping = SFBeginPropertyMappingWithClass(TSScriptNodeStyle)
    SFMappingPropertyToKey(backgroundColor, @"background_color")
    SFMappingPropertyToKey(textColor, @"text_color")
    SFMappingPropertyToKey(borderColor, @"border_color")
    SFMappingPropertyToKey(borderWidth, @"border_width")
    SFMappingPropertyToKey(cornerRadius, @"corner_radius")
    SFMappingPropertyToKey(fontSize, @"font_size")
    SFMappingPropertyToKey(maxWidth, @"max_width")
    SFMappingPropertyToKey(minWidth, @"min_width")
    SFMappingPropertyToKey(horizontalSpacing, @"hspacing")
    SFMappingPropertyToKey(verticalSpacing, @"vspacing")
    SFMappingPropertyToKey(viewClassName, @"view_class_name")
    SFMappingPropertyToKey(connectionViewClassName, @"connection_view_class_name")
    SFMappingPropertyToKey(connectionViewAttributes, @"connection_view_attrs")
    SFMappingPropertyToClass(subnodes, TSScriptNodeStyle)
    SFEndPropertyMapping;
    id(^colorProcessor)(NSString *) = ^UIColor *(NSString *value) {
        return [NSString colorWithAttrValue:value];
    };
    SFPropertyProcessor *alignmentProcessor = [SFPropertyProcessor propertyProcessorWithClass:[TSScriptNodeStyle class] propertyName:SFGetPropertyName(TSScriptNodeStyle, alignment) processing:^id(NSString *value) {
        TSNodeContentAlignment alignment = [TSDefaultMindViewStyle shared].alignment;
        NSString *lowerValue = [value lowercaseString];
        if ([lowerValue isEqualToString:@"left"]) {
            alignment = TSNodeContentAlignmentLeft;
        } else if ([lowerValue isEqualToString:@"center"]) {
            alignment = TSNodeContentAlignmentCenter;
        } else if ([lowerValue isEqualToString:@"right"]) {
            alignment = TSNodeContentAlignmentRight;
        }
        
        return [NSNumber numberWithUnsignedInteger:alignment];
    }];
    
    NSArray *propertyProcessors = @[alignmentProcessor, [SFPropertyProcessor propertyProcessorWithClass:[TSScriptNodeStyle class] propertyName:SFGetPropertyName(TSMutableNodeStyle, backgroundColor) processing:colorProcessor],
                                    [SFPropertyProcessor propertyProcessorWithClass:[TSScriptNodeStyle class] propertyName:SFGetPropertyName(TSMutableNodeStyle, textColor) processing:colorProcessor],
                                    [SFPropertyProcessor propertyProcessorWithClass:[TSScriptNodeStyle class] propertyName:SFGetPropertyName(TSMutableNodeStyle, borderColor) processing:colorProcessor]];
    TSScriptNodeStyle *style = [TSScriptNodeStyle sf_objectFromDictionary:resultDict mapping:mapping propertyProcessors:propertyProcessors];
    [self _presetStyle:style node:node];
}

- (void)_presetStyle:(TSScriptNodeStyle *)style node:(TSNode *)node {
    [node setStyle:style];
    if (node.subnodes != nil && node.subnodes.count > 0) {
        for (NSUInteger i = 0; i < node.subnodes.count; ++i) {
            TSNode *subNode = [node.subnodes objectAtIndex:i];
            TSScriptNodeStyle *subStyle = [style.subnodes objectAtIndex:i];
            NSAssert(subStyle != nil, @"Error on finding style for node:%@", subNode.title);
            [self _presetStyle:subStyle node:subNode];
        }
    }
}

- (id<TSNodeStyle>)styleForNode:(TSNode *)node {
    id<TSNodeStyle> style = [node style];
    if (style == nil) {
        style = [TSDefaultMindViewStyle shared];
    }
    
    return style;
}

@end

