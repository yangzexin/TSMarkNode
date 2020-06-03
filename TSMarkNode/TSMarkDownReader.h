//
//  TSMarkDownReader.h
//  Markdown
//
//  Created by yangzexin on 2020/5/13.
//  Copyright © 2020 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <SFFoundation/SFFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TSMarkDownReader : SFServant

@property (nonatomic, copy) NSString *defaultTitleForRootNode;

- (instancetype)initWithFile:(NSString *)file;

- (instancetype)initWithURLString:(NSString *)URLString;

@end

NS_ASSUME_NONNULL_END
