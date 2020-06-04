//
//  TSLayouter+Private.h
//  TSMarkNode
//
//  Created by yangzexin on 2020/5/20.
//  Copyright © 2020 yangzexin. All rights reserved.
//

#ifndef TSLayouter_Private_h
#define TSLayouter_Private_h

@interface TSNodeLayoutResult ()

@property (nonatomic, assign) CGRect frame;
@property (nonatomic, assign) CGFloat allWidth;
@property (nonatomic, strong) NSArray<TSNodeLayoutResult *> *subNodeResults;

@property (nonatomic, weak) TSNode *node;

@property (nonatomic, weak) TSNodeLayoutResult *parent;

@end

@interface TSLayoutResult ()

@property (nonatomic, strong) TSNodeLayoutResult *nodeLayoutResult;
@property (nonatomic, assign) CGRect initialDisplayRect;

@end

#endif /* TSLayouter_Private_h */
