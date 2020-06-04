//
//  TSScriptMindViewTheme.h
//  TSMarkNode
//
//  Created by yangzexin on 2020/5/19.
//  Copyright © 2020 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSNodeStyle.h"
#import "TSLuaEngine.h"

NS_ASSUME_NONNULL_BEGIN

@interface TSScriptMindViewStyle : NSObject <TSMindViewStyle>

@property (nonatomic, strong) TSLuaEngine *luaEngine;

- (instancetype)initWithEngine:(TSLuaEngine *)engine;

@end
NS_ASSUME_NONNULL_END
