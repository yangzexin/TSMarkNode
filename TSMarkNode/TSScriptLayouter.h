//
//  TSScriptLayouter.h
//  Markdown
//
//  Created by yangzexin on 2020/5/19.
//  Copyright © 2020 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSLayouter.h"
#import "TSLuaEngine.h"

NS_ASSUME_NONNULL_BEGIN

@interface TSScriptLayouter : TSLayouter

@property (nonatomic, strong) TSLuaEngine *luaEngine;

+ (NSArray *)layouterNamesWithLuaEngine:(TSLuaEngine *)luaEngine;

@end

NS_ASSUME_NONNULL_END
