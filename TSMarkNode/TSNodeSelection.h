//
//  TSNodeSelection.h
//  TSMarkNode
//
//  Created by yangzexin on 2020/5/14.
//  Copyright © 2020 yangzexin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class TSNode;

NS_ASSUME_NONNULL_BEGIN

@interface TSNodeSelection : NSObject

@property (nonatomic, assign) CGRect frame;
@property (nonatomic, strong) TSNode *node;

@property (nonatomic, assign) id context;

@end

NS_ASSUME_NONNULL_END
