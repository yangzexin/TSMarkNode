//
//  TSNode.h
//  Markdown
//
//  Created by yangzexin on 2020/5/13.
//  Copyright © 2020 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TSNode : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) NSMutableArray<TSNode *> *subnodes;

@property (nonatomic, copy, nullable) NSString *attributes;
@property (nonatomic, assign) NSUInteger level;
@property (nonatomic, weak, nullable) TSNode *parent;

@end

NS_ASSUME_NONNULL_END
