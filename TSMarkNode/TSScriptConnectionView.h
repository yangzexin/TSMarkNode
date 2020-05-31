//
//  TSScriptConnectionView.h
//  Markdown
//
//  Created by yangzexin on 2020/5/19.
//  Copyright © 2020 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSConnectionView.h"

NS_ASSUME_NONNULL_BEGIN

@interface TSScriptConnectionView : TSSimpleConnectionView

@property (nonatomic, assign) NSUInteger engineId;

@property (nonatomic, copy) NSString *type;

@end

NS_ASSUME_NONNULL_END
