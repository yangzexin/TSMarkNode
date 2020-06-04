//
//  TSNode+LayoutAddition.m
//  TSMarkNode
//
//  Created by yangzexin on 2020/5/15.
//  Copyright © 2020 yangzexin. All rights reserved.
//

#import "TSNode+LayoutAddition.h"
#import <SFFoundation/SFFoundation.h>
#import <SFiOSKit/SFiOSKit.h>

@implementation TSNode (Conext)

- (void)setContext:(id)context {
    [self sf_setAssociatedObject:context key:@"_context"];
}

- (id)context {
    return [self sf_associatedObjectWithKey:@"_context"];
}

- (void)setRootNode:(BOOL)rootNode {
    [self sf_setAssociatedObject:[NSNumber numberWithBool:rootNode] key:@"_isRootNode"];
}

- (BOOL)isRootNode {
    NSNumber *n = [self sf_associatedObjectWithKey:@"_isRootNode"];
    if (n != nil) {
        return [n boolValue];
    }
    
    return NO;
}

@end

@implementation NSString (Attribute)

+ (UIColor *)colorWithAttrValue:(NSString *)value {
    NSArray *attrs = [value componentsSeparatedByString:@","];
    if (attrs.count > 2) {
        NSInteger red = [[attrs objectAtIndex:0] integerValue];
        NSInteger green = [[attrs objectAtIndex:1] integerValue];
        NSInteger blue = [[attrs objectAtIndex:2] integerValue];
        NSInteger alpha = 100;
        if (attrs.count > 3) {
            alpha = [[attrs objectAtIndex:3] integerValue];
        }
        return [UIColor sf_colorWithRed:red green:green blue:blue alpha:alpha];
    }
    
    return nil;
}

@end

@implementation TSNode (Attribute)

- (void)processAttribute:(NSString *)attribute {
    if ([attribute hasPrefix:@"style="]) {
        [self addPreferedStyleWithAttributeStyle:attribute];
    } else if ([attribute hasPrefix:@"base64encoded"]) {
        NSString *originalTitle = [[NSString alloc] initWithData:[[NSData alloc] initWithBase64EncodedString:self.title options:0] encoding:NSUTF8StringEncoding];
        self.title = originalTitle;
    }
}

+ (NSString *)processTitle:(NSString *)title {
    title = [title stringByReplacingOccurrencesOfString:@"<br/>" withString:@"\n"];
    
    return title;
}

@end

@implementation TSPreferedNodeStyle (PreferedStyle)

- (void)setWithStyleSet:(NSString *)styleSet {
    NSArray *keyValue = [styleSet componentsSeparatedByString:@":"];
    if (keyValue.count == 2) {
        NSString *key = [[keyValue objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSString *value = [[keyValue objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        [self _setWithKey:key value:value];
    }
}

- (void)_addAttr:(NSString *)value to:(NSMutableDictionary *)dictionary {
    NSArray *keyValue = [value componentsSeparatedByString:@"="];
    if (keyValue.count == 2) {
        NSString *key = [[keyValue objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSString *value = [[keyValue objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        [dictionary setObject:value forKey:key];
    } else {
        NSLog(@"Warning: invalid format: %@", keyValue);
    }
}

- (void)_setWithKey:(NSString *)key value:(NSString *)value {
    if ([key isEqualToString:@"bg-color"]) {
        self.backgroundColor = [NSString colorWithAttrValue:value];
        [self setAttributeHasVaue:SFGetPropertyName(TSPreferedNodeStyle, backgroundColor)];
    } else if ([key isEqualToString:@"text-color"]) {
        self.textColor = [NSString colorWithAttrValue:value];
        [self setAttributeHasVaue:SFGetPropertyName(TSPreferedNodeStyle, textColor)];
    } else if ([key isEqualToString:@"border-color"]) {
        self.borderColor = [NSString colorWithAttrValue:value];
        [self setAttributeHasVaue:SFGetPropertyName(TSPreferedNodeStyle, borderColor)];
    } else if ([key isEqualToString:@"border-width"]) {
        self.borderWidth = [value integerValue];
        [self setAttributeHasVaue:SFGetPropertyName(TSPreferedNodeStyle, borderWidth)];
    } else if ([key isEqualToString:@"corner-radius"]) {
        self.cornerRadius = [value integerValue];
        [self setAttributeHasVaue:SFGetPropertyName(TSPreferedNodeStyle, cornerRadius)];
    } else if ([key isEqualToString:@"max-width"]) {
        self.maxWidth = [value integerValue];
        [self setAttributeHasVaue:SFGetPropertyName(TSPreferedNodeStyle, maxWidth)];
    } else if ([key isEqualToString:@"min-width"]) {
        self.minWidth = [value integerValue];
        [self setAttributeHasVaue:SFGetPropertyName(TSPreferedNodeStyle, minWidth)];
    } else if ([key isEqualToString:@"font-size"]) {
        self.fontSize = [value integerValue];
        [self setAttributeHasVaue:SFGetPropertyName(TSPreferedNodeStyle, fontSize)];
    } else if ([key isEqualToString:@"padding"]) {
        self.padding = [value integerValue];
        [self setAttributeHasVaue:SFGetPropertyName(TSPreferedNodeStyle, padding)];
    } else if ([key isEqualToString:@"alignment"]) {
        NSString *lowerAlignment = [value lowercaseString];
        if ([lowerAlignment isEqualToString:@"left"]) {
            self.alignment = TSNodeContentAlignmentLeft;
            [self setAttributeHasVaue:SFGetPropertyName(TSPreferedNodeStyle, alignment)];
        } else if ([lowerAlignment isEqualToString:@"center"]) {
            self.alignment = TSNodeContentAlignmentCenter;
            [self setAttributeHasVaue:SFGetPropertyName(TSPreferedNodeStyle, alignment)];
        } else if ([lowerAlignment isEqualToString:@"right"]) {
            self.alignment = TSNodeContentAlignmentRight;
            [self setAttributeHasVaue:SFGetPropertyName(TSPreferedNodeStyle, alignment)];
        }
    } else if ([key isEqualToString:@"vspacing"]) {
        self.verticalSpacing = [value integerValue];
        [self setAttributeHasVaue:SFGetPropertyName(TSPreferedNodeStyle, verticalSpacing)];
    } else if ([key isEqualToString:@"hspacing"]) {
        self.horizontalSpacing = [value integerValue];
        [self setAttributeHasVaue:SFGetPropertyName(TSPreferedNodeStyle, horizontalSpacing)];
    } else if ([key isEqualToString:@"view-class"]) {
        self.viewClassName = value;
        [self setAttributeHasVaue:SFGetPropertyName(TSPreferedNodeStyle, viewClassName)];
    } else if ([key isEqualToString:@"conn-view-class"]) {
        self.connectionViewClassName = value;
        [self setAttributeHasVaue:SFGetPropertyName(TSPreferedNodeStyle, connectionViewClassName)];
    } else if ([key isEqualToString:@"conn-view-attr"]) {
        NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
        if (self.connectionViewAttributes) {
            [attrs addEntriesFromDictionary:self.connectionViewAttributes];
        }
        [self _addAttr:value to:attrs];
        self.connectionViewAttributes = attrs;
        [self setAttributeHasVaue:SFGetPropertyName(TSPreferedNodeStyle, connectionViewAttributes)];
    } else if ([key isEqualToString:@"sub-alignment"]) {
        NSString *lowerAlignment = [value lowercaseString];
        if ([lowerAlignment isEqualToString:@"top"]) {
            self.subAlignment = TSNodeSubAlignmentTop;
            [self setAttributeHasVaue:SFGetPropertyName(TSPreferedNodeStyle, subAlignment)];
        } else if ([lowerAlignment isEqualToString:@"center"]) {
            self.subAlignment = TSNodeSubAlignmentCenter;
            [self setAttributeHasVaue:SFGetPropertyName(TSPreferedNodeStyle, subAlignment)];
        }
    }
}

@end

@implementation TSNode (Style)

- (id<TSNodeStyle>)styleByWrappingWithPreferedStyle:(id<TSNodeStyle>)originalStyle {
    TSPreferedNodeStyle *preferedStyle = [self preferedStyle];
    if (!preferedStyle || [preferedStyle empty]) {
        return originalStyle;
    }
    
    TSMutableNodeStyle *style = [[TSMutableNodeStyle alloc] initWithStyle:originalStyle];
    for (NSString *attribute in preferedStyle.attributeSet) {
        if ([attribute isEqualToString:SFGetPropertyName(TSPreferedNodeStyle, connectionViewAttributes)]) {
            NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:preferedStyle.connectionViewAttributes];
            if (style.connectionViewAttributes) {
                [attributes addEntriesFromDictionary:style.connectionViewAttributes];
            }
            style.connectionViewAttributes = attributes;
        } else {
            id value = [preferedStyle valueForKey:attribute];
            [style setValue:value forKey:attribute];
        }
    }
    
    return style;
}

- (void)setStyle:(id<TSNodeStyle>)style {
    [self sf_setAssociatedObject:style key:@"_style"];
}

- (id<TSNodeStyle>)style {
    return [self sf_associatedObjectWithKey:@"_style"];
}

- (void)addPreferedStyleWithAttributeStyle:(NSString *)attrStyle {
    if ([attrStyle hasPrefix:@"style="]) {
        TSPreferedNodeStyle *style = [self preferedStyle];
        if (style == nil) {
            style = [TSPreferedNodeStyle new];
            [self setPreferedStyle:style];
        }
        NSArray *styleSets = [[attrStyle substringFromIndex:6] componentsSeparatedByString:@";"];
        for (NSString *styleSet in styleSets) {
            [style setWithStyleSet:styleSet];
        }
    }
}

- (BOOL)isPreferedStyleSetWithAttribute:(NSString *)attr {
    return [[self preferedStyle] isAttributeHasValue:attr];
}

- (void)setPreferedStyle:(TSPreferedNodeStyle *)preferedStyle {
    [self sf_setAssociatedObject:preferedStyle key:@"_prefered_style"];
}

- (TSPreferedNodeStyle *)preferedStyle {
    return [self sf_associatedObjectWithKey:@"_prefered_style"];
}

- (NSDictionary *)preferedStyleDictionary {
    TSPreferedNodeStyle *style = [self preferedStyle];
    if (style == nil) {
        return nil;
    }
    NSSet *attributeSet = [style attributeSet];
    NSMutableArray *properties = [NSMutableArray array];
    for (NSString *attr in attributeSet) {
        [properties addObject:[SFObjcProperty objcPropertyWithPropertyName:attr targetClass:[TSPreferedNodeStyle class]]];
    }
    NSDictionary *dict = [style sf_dictionaryWithSpecificObjcProperties:properties NSNumberForPlainType:YES];
    
    return dict;
}

@end

@implementation TSNode (DisplayLevel)

- (void)setDisplayLevel:(NSNumber *)displayLevel {
    [self sf_setAssociatedObject:displayLevel key:@"_displayLevel"];
}

- (NSNumber *)displayLevel {
    NSNumber *number = [self sf_associatedObjectWithKey:@"_displayLevel"];
    
    return number;
}

@end

@interface _TSNodeObserver : NSObject <SFDepositable>

@property (nonatomic, copy) void(^observer)(void);

@end

@implementation _TSNodeObserver

- (BOOL)shouldRemoveDepositable {
    return self.observer == nil;
}

- (void)depositableWillRemove {
    self.observer = nil;
}

@end

@interface _TSNewNodeObserver : NSObject <SFDepositable>

@property (nonatomic, copy) void(^observer)(TSNode *);

@end

@implementation _TSNewNodeObserver

- (BOOL)shouldRemoveDepositable {
    return self.observer == nil;
}

- (void)depositableWillRemove {
    self.observer = nil;
}

@end

@implementation TSNode (Observer)

- (id<SFDepositable>)addRemoveObserver:(void(^)(void))observer {
    NSMutableArray *observerList = [self sf_associatedObjectWithKey:@"_removeObservers"];
    if (observerList == nil) {
        observerList = [NSMutableArray array];
        [self sf_setAssociatedObject:observerList key:@"_removeObservers"];
    }
    _TSNodeObserver *removeObserver = [_TSNodeObserver new];
    removeObserver.observer = observer;
    [observerList addObject:removeObserver];

    return removeObserver;
}

- (void)notifyRemoveObserver {
    NSMutableArray *observerList = [self sf_associatedObjectWithKey:@"_removeObservers"];
    if (observerList) {
        for (_TSNodeObserver *observer in observerList) {
            if (observer.observer) {
                observer.observer();
            }
        }
    }
}

- (id<SFDepositable>)addNewSubnodeObserver:(void(^)(TSNode *newSubnode))observer {
    NSMutableArray *observerList = [self sf_associatedObjectWithKey:@"_newSubnodeObservers"];
    if (observerList == nil) {
        observerList = [NSMutableArray array];
        [self sf_setAssociatedObject:observerList key:@"_newSubnodeObservers"];
    }
    _TSNewNodeObserver *removeObserver = [_TSNewNodeObserver new];
    removeObserver.observer = observer;
    [observerList addObject:removeObserver];
    
    return removeObserver;
}

- (void)notifyNewSubnodeObserver:(TSNode *)newSubnode {
    NSMutableArray *observerList = [self sf_associatedObjectWithKey:@"_newSubnodeObservers"];
    if (observerList) {
        for (_TSNewNodeObserver *observer in observerList) {
            if (observer.observer) {
                observer.observer(newSubnode);
            }
        }
    }
}

@end

@implementation TSNode (Traverse)

+ (void)traverseNode:(TSNode *)node block:(void(^)(TSNode *node))block {
    if (node.subnodes && node.subnodes.count > 0) {
        for (TSNode *subNode in node.subnodes) {
            [self traverseNode:subNode block:block];
        }
    }
    block(node);
}

- (BOOL)isDescendantOfNode:(TSNode *)node {
    TSNode *tmp = self;
    while ((tmp = tmp.parent) != nil) {
        if (tmp == node) {
            return YES;
        }
    }
    return NO;
}

- (NSDictionary *)dictionary {
    return [[self class] dictionaryForNode:self];
}

+ (NSDictionary *)dictionaryForNode:(TSNode *)node {
    return [self dictionaryForNode:node wrapper:nil];
}

+ (NSMutableDictionary *)dictionaryForNode:(TSNode *)node wrapper:(nullable void(^)(TSNode *item, NSMutableDictionary *dict))wrapper {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"title"] = node.title;
    dict[@"level"] = [NSNumber numberWithInteger:node.level];
    dict[@"attributes"] = node.attributes;
    dict[@"preferedStyle"] = [node preferedStyleDictionary];
    if (wrapper != nil) {
        wrapper(node, dict);
    }
    
    if (node.subnodes.count != 0) {
        NSMutableArray *subnodes = [NSMutableArray arrayWithCapacity:node.subnodes.count];
        for (TSNode *subNode in node.subnodes) {
            [subnodes addObject:[self dictionaryForNode:subNode wrapper:wrapper]];
        }
        dict[@"subnodes"] = subnodes;
    }
    
    return dict;
}

@end

@implementation TSNode (Dragging)

- (void)setDragging:(BOOL)dragging {
    [self sf_setAssociatedObject:[NSNumber numberWithBool:dragging] key:@"_dragging"];
}

- (BOOL)isDragging {
    NSNumber *n = [self sf_associatedObjectWithKey:@"_dragging"];
    if (n != nil) {
        return [n boolValue];
    }
    return NO;
}

- (void)setTempAdd:(BOOL)tempAdd {
    [self sf_setAssociatedObject:[NSNumber numberWithBool:tempAdd] key:@"_tempAdd"];
}

- (BOOL)isTempAdd {
    NSNumber *n = [self sf_associatedObjectWithKey:@"_tempAdd"];
    if (n != nil) {
        return [n boolValue];
    }
    return NO;
}

- (TSNode *)copyForDragging {
    return [self _copyNode:self];
}

- (TSNode *)_copyNode:(TSNode *)node {
    TSNode *newNode = [TSNode new];
    [newNode setTempAdd:YES];
    newNode.title = [node.title copy];
    newNode.level = node.level;
    newNode.attributes = [node.attributes copy];
    NSMutableArray<TSNode *> *tmpSubnodes = [NSMutableArray arrayWithCapacity:node.subnodes.count];
    for (TSNode *subNode in node.subnodes) {
        TSNode *newSubNode = [self _copyNode:subNode];
        newSubNode.parent = newNode;
        [tmpSubnodes addObject:newSubNode];
    }
    newNode.subnodes = tmpSubnodes;
    newNode.parent = node.parent;
    newNode.displayLevel = node.displayLevel;
    [newNode setPreferedStyle:[node preferedStyle]];
    
    return newNode;
}

@end

@implementation TSNode (Operations)

- (NSUInteger)removeFromParent {
    TSNode *parent = self.parent;
    self.parent = nil;
    NSUInteger index = [parent.subnodes indexOfObject:self];
    if (index != NSNotFound) {
        [parent.subnodes removeObjectAtIndex:index];
    } else {
        NSLog(@"Warning: try removing child node:%@ which is not in subnodes of parent node", [self title]);
    }
    
    [TSNode traverseNode:self block:^(TSNode * _Nonnull n) {
        [n notifyRemoveObserver];
    }];
    
    return index;
}

- (void)addNodeAsSub:(TSNode *)node index:(NSUInteger)index {
    node.parent = self;
    [self.subnodes insertObject:node atIndex:index];
    [self notifyNewSubnodeObserver:node];
}

- (void)addNodeAsSub:(TSNode *)node {
    node.parent = self;
    [self.subnodes addObject:node];
    [self notifyNewSubnodeObserver:node];
}

- (TSNode *)addNodeAsSubWithTitle:(NSString *)title {
    TSNode *node = [TSNode new];
    node.title = title;
    node.subnodes = [NSMutableArray array];
    [self addNodeAsSub:node];
    return node;
}

- (TSNode *)addNodeAsNextSiblingWithTitle:(NSString *)title {
    TSNode *node = [TSNode new];
    node.title = title;
    node.subnodes = [NSMutableArray array];
    [self addNodeAsNextSibling:node exceptNode:self];
    return node;
}

- (BOOL)addNodeAsSub:(TSNode *)node exceptNode:(TSNode *)exceptNode {
    if ([self.subnodes indexOfObject:exceptNode] != NSNotFound) {
        return NO;
    }
    [self addNodeAsSub:node];
    return YES;
}

- (BOOL)addNodeAsNextSibling:(TSNode *)node exceptNode:(TSNode *)exceptNode {
    TSNode *parentNode = self.parent;
    NSUInteger index = [parentNode.subnodes indexOfObject:self];
    if (index == NSNotFound) {
        NSLog(@"Warning: addNodeAsNextSibling node not in parent subnodes");
        return NO;
    }
    ++index;
    if (index != parentNode.subnodes.count && [parentNode.subnodes objectAtIndex:index] == exceptNode) {
        return NO;
    }
    node.parent = self.parent;
    [parentNode.subnodes insertObject:node atIndex:index];
    [parentNode notifyNewSubnodeObserver:node];
    
    return YES;
}

- (BOOL)addNodeAsPreviousSibling:(TSNode *)node exceptNode:(TSNode *)exceptNode {
    TSNode *parentNode = self.parent;
    NSUInteger index = [parentNode.subnodes indexOfObject:self];
    if (index == NSNotFound) {
        NSLog(@"Warning: addNodeAsPreviousSibling node not in parent subnodes");
        return NO;
    }
    if (index != 0 && [parentNode.subnodes objectAtIndex:index - 1] == exceptNode) {
        return NO;
    }
    node.parent = self.parent;
    [parentNode.subnodes insertObject:node atIndex:index];
    [parentNode notifyNewSubnodeObserver:node];
    
    return YES;
}

@end
