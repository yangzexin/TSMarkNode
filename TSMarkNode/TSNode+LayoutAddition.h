//
//  TSNode+Context.h
//  Markdown
//
//  Created by yangzexin on 2020/5/15.
//  Copyright © 2020 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SFFoundation/SFFoundation.h>
#import "TSNode.h"
#import "TSNodeStyle.h"

NS_ASSUME_NONNULL_BEGIN

@interface TSNode (Context)

@property (nonatomic, strong, nullable) id context;

@property (nonatomic, assign, getter=isRootNode) BOOL rootNode;

@end

@interface TSPreferedNodeStyle (PreferedStyle)

- (void)setWithStyleSet:(NSString *)styleSet;

@end

@interface NSString (Attribute)

+ (UIColor *)colorWithAttrValue:(NSString *)value;

@end

@interface TSNode (Attribute)

- (void)processAttribute:(NSString *)attribute;

+ (NSString *)processTitle:(NSString *)title;

@end

@interface TSNode (Style)

- (void)setStyle:(id<TSNodeStyle>)style;
- (id<TSNodeStyle>)style;

- (void)addPreferedStyleWithAttributeStyle:(NSString *)attrStyle;

- (BOOL)isPreferedStyleSetWithAttribute:(NSString *)attr;

- (id<TSNodeStyle>)styleByWrappingWithPreferedStyle:(id<TSNodeStyle>)style;

@end

@interface TSNode (DisplayLevel)

@property (nonatomic, strong) NSNumber *displayLevel;

@end

@interface TSNode (Observer)

- (id<SFDepositable>)addRemoveObserver:(void(^)(void))observer;

- (void)notifyRemoveObserver;

- (id<SFDepositable>)addNewSubnodeObserver:(void(^)(TSNode *newSubnode))observer;

@end

@interface TSNode (Traverse)

+ (void)traverseNode:(TSNode *)node block:(void(^)(TSNode *node))block;

- (BOOL)isDescendantOfNode:(TSNode *)node;

- (NSDictionary *)dictionary;

+ (NSMutableDictionary *)dictionaryForNode:(TSNode *)node wrapper:(nullable void(^)(TSNode *item, NSMutableDictionary *dict))wrapper;

@end

@interface TSNode (Dragging)

@property (nonatomic, assign, getter=isDragging) BOOL dragging;
@property (nonatomic, assign, getter=isTempAdd) BOOL tempAdd;

- (TSNode *)copyForDragging;

@end

@interface TSNode (Operations)

- (NSUInteger)removeFromParent;

- (void)addNodeAsSub:(TSNode *)node index:(NSUInteger)index;
- (void)addNodeAsSub:(TSNode *)node;

- (BOOL)addNodeAsSub:(TSNode *)node exceptNode:(TSNode *)exceptNode;

- (BOOL)addNodeAsNextSibling:(TSNode *)node exceptNode:(TSNode *)exceptNode;

- (BOOL)addNodeAsPreviousSibling:(TSNode *)node exceptNode:(TSNode *)exceptNode;

@end

NS_ASSUME_NONNULL_END
