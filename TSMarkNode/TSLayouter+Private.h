//
//  TSLayouter+Private.h
//  Markdown
//
//  Created by yangzexin on 2020/5/20.
//  Copyright © 2020 yangzexin. All rights reserved.
//

#ifndef TSLayouter_Private_h
#define TSLayouter_Private_h

@interface TSLayoutResult ()

@property (nonatomic, assign) CGRect frame;
@property (nonatomic, assign) CGFloat allWidth;
@property (nonatomic, strong) NSArray<TSLayoutResult *> *subNodeResults;

@property (nonatomic, weak) TSNode *node;

@property (nonatomic, weak) TSLayoutResult *parent;

@end

#endif /* TSLayouter_Private_h */
