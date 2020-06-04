//
//  TSMarkDownReader.m
//  TSMarkNode
//
//  Created by yangzexin on 2020/5/13.
//  Copyright © 2020 yangzexin. All rights reserved.
//

#import "TSMarkDownReader.h"
#import "TSNode.h"
#import "TSNode+LayoutAddition.h"

@interface TSMarkDownReader ()

@property (nonatomic, copy) NSString *file;

@property (nonatomic, copy) NSString *URLString;

@end

@implementation TSMarkDownReader

- (instancetype)init {
    self = [super init];
    
    return self;
}

- (instancetype)initWithFile:(NSString *)file {
    self = [self init];
    
    self.file = file;
    
    return self;
}

- (instancetype)initWithURLString:(NSString *)URLString {
    self = [self init];
    
    self.URLString = URLString;
    
    return self;
}

- (void)_checkIfCreateRootNodeWithDefaultTitle:(NSString *)title lines:(NSArray *)lines stack:(NSMutableArray *)stack {
    NSMutableDictionary<NSNumber *, NSNumber *> *keyLevelValueCount = [NSMutableDictionary dictionary];
    NSUInteger minLevel = 999;
    for (NSString *line in lines) {
        if ([line hasPrefix:@"#"]) {
            TSNode *node = [self _getNode:line onlyLevel:YES];
            if (node != nil) {
                if (node.level < minLevel) {
                    minLevel = node.level;
                }
                NSNumber *count = keyLevelValueCount[@(node.level)];
                if (count == nil) {
                    count = @1;
                } else {
                    count = @(count.unsignedIntegerValue + 1);
                }
                keyLevelValueCount[@(node.level)] = count;
            }
        }
    }
    NSNumber *count = keyLevelValueCount[@(minLevel)];
    if (count.unsignedIntegerValue != 1) {
        TSNode *rootNode = [TSNode new];
        rootNode.level = 0;
        rootNode.title = title == nil ? (self.defaultTitleForRootNode == nil ? @"Untitled" : self.defaultTitleForRootNode) : title;
        rootNode.subnodes = [NSMutableArray array];
        
        [stack addObject:rootNode];
    }
}

- (void)servantStartingService {
    [super servantStartingService];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        NSString *contents = nil;
        NSString *defaultTitle = nil;
        if (self.file) {
            defaultTitle = [self.file lastPathComponent];
            contents = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:self.file ofType:nil] encoding:NSUTF8StringEncoding error:&error];
            if (error) {
                [self returnWithFeedback:[SFServantFeedback feedbackWithError:error]];
                return;
            }
        } else if (self.URLString) {
            defaultTitle = [self.URLString lastPathComponent];
            contents = [NSString stringWithContentsOfURL:[NSURL URLWithString:self.URLString] encoding:NSUTF8StringEncoding error:&error];
            if (error) {
                [self returnWithFeedback:[SFServantFeedback feedbackWithError:error]];
                return;
            }
        } else {
            [self returnWithFeedback:[SFServantFeedback feedbackWithError:[NSError errorWithDomain:NSStringFromClass(self.class) code:-1 userInfo:@{NSLocalizedDescriptionKey: @"illegal file or url"}]]];
        }
        
        NSMutableArray<TSNode *> *stack = [NSMutableArray array];
        TSNode *latestAddNode = nil;
        TSNode *latestAttributeNode = nil;
        NSArray<NSString *> *lines = [contents componentsSeparatedByString:@"\n"];
        [self _checkIfCreateRootNodeWithDefaultTitle:defaultTitle lines:lines stack:stack];
        for (NSUInteger i = 0; i < lines.count; ++i) {
            NSString *originalLine = [lines objectAtIndex:i];
            NSString *line = [originalLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if ([line length] == 0) {
                continue;
            }
            TSNode *lastNode = [stack lastObject];
            if (lastNode == nil) {
                if (![line hasPrefix:@"#"]) {
                    continue;
                }
                TSNode *node = [self _getNode:line];
                if (node != nil) {
                    latestAddNode = node;
                    latestAttributeNode = node;
                    [stack addObject:node];
                }
                continue;
            }
            
            if ([line hasPrefix:@"#"]) {
                TSNode *node = [self _getNode:line];
                if (node != nil) {
                    latestAddNode = node;
                    latestAttributeNode = node;
                    if (node.level == lastNode.level) {
                        [stack addObject:node];
                        [(NSMutableArray *)lastNode.parent.subnodes addObject:node];
                        node.parent = lastNode.parent;
                        continue;
                    } else if (node.level > lastNode.level) {
                        [stack addObject:node];
                        [(NSMutableArray *) lastNode.subnodes addObject:node];
                        node.parent = lastNode;
                    } else if (node.level < lastNode.level) {
                        while ([[stack lastObject] level] >= node.level) {
                            [stack removeLastObject];
                        }
                        lastNode = [stack lastObject];
                        assert(lastNode != nil);
                        [stack addObject:node];
                        [(NSMutableArray *) lastNode.subnodes addObject:node];
                        node.parent = lastNode;
                    }
                }
            } else if ([line hasPrefix:@"<!--"]) {
                NSMutableString *comment = [NSMutableString stringWithString:line];
                if (![comment hasSuffix:@"-->"]) {
                    while (YES) {
                        NSString *nextOriginalLine = [lines objectAtIndex:++i];
                        NSString *nextLine = [nextOriginalLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                        [comment appendString:nextLine];
                        if ([nextLine hasSuffix:@"-->"] || i == lines.count - 1) {
                            break;
                        }
                    }
                }
                if (latestAttributeNode != nil) {
                    NSMutableString *attributes = [NSMutableString string];
                    if (latestAttributeNode.attributes) {
                        [attributes appendString:latestAttributeNode.attributes];
                        [attributes appendString:@"\n"];
                    }
                    
                    [self _getAttributesFromComment:comment block:^(NSString *attribute) {
                        [attributes appendString:attribute];
                        [attributes appendString:@"\n"];
                        [latestAttributeNode processAttribute:attribute];
                    }];
                    latestAttributeNode.attributes = attributes;
                } else {
                    NSLog(@"Warning: Attributes found, but target node is nil: %@", line);
                }
            } else {
                if (latestAddNode != nil) {
                    latestAttributeNode = [self _addSubtextNode:line parentNode:latestAddNode];
                } else {
                    NSLog(@"Warning: Subtext found, but target node is nil: %@", line);
                }
            }
        }
        [self returnWithFeedback:[SFServantFeedback feedbackWithValue:[stack firstObject]]];
    });
}

- (void)_getAttributesFromComment:(NSMutableString *)comment block:(void(^)(NSString *attribute))block {
    NSString *matching = @"!ATTRIBUTE:";
    NSInteger beginIndex = [comment sf_find:matching];
    if (beginIndex != -1) {
        while (YES) {
            NSInteger nextIndex = [comment sf_find:matching fromIndex:beginIndex + matching.length];
            NSInteger endIndex = nextIndex == -1 ? ([comment length] - 3) : nextIndex;
            
            NSString *originalAttribute = [comment sf_substringWithBeginIndex:beginIndex + matching.length endIndex:endIndex];
            NSString *attribute = [originalAttribute stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            block(attribute);
            if (nextIndex != -1) {
                beginIndex = endIndex;
            } else {
                break;
            }
        }
    }
}

- (TSNode *)_addSubtextNode:(NSString *)subText parentNode:(TSNode *)parentNode {
    TSNode *node = [TSNode new];
    node.level = parentNode.level + 1;
    node.title = [TSNode processTitle:subText];
    node.subnodes = [NSMutableArray array];
    [parentNode.subnodes addObject:node];
    node.parent = parentNode;
    
    return node;
}

- (TSNode *)_getNode:(NSString *)line {
    return [self _getNode:line onlyLevel:NO];
}

- (TSNode *)_getNode:(NSString *)line onlyLevel:(BOOL)onlyLevel {
    NSUInteger whitespaceIndex = [line sf_find:@" "];
    if (whitespaceIndex == -1) {
        NSLog(@"Warning: invalid format: %@", line);
        return nil;
    }
    TSNode *node = [TSNode new];
    node.level = whitespaceIndex;
    if (!onlyLevel) {
        node.title = [TSNode processTitle:[line sf_substringWithBeginIndex:whitespaceIndex + 1 endIndex:line.length]];
        node.subnodes = [NSMutableArray array];
    }
    
    return node;
}

@end
