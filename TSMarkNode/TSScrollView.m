//
//  TSScrollView.m
//  Markdown
//
//  Created by yangzexin on 2020/5/13.
//  Copyright © 2020 yangzexin. All rights reserved.
//

#import "TSScrollView.h"

@interface TSScrollView ()

@end

@implementation TSScrollView

- (void)setContentOffset:(CGPoint)anOffset {
    if(self.centerView != nil) {
        CGSize zoomViewSize = self.centerView.frame.size;
        CGSize scrollViewSize = self.bounds.size;
        
        if(zoomViewSize.width < scrollViewSize.width) {
            anOffset.x = -(scrollViewSize.width - zoomViewSize.width) / 2.0;
        }
        
        if(zoomViewSize.height < scrollViewSize.height) {
            anOffset.y = -(scrollViewSize.height - zoomViewSize.height) / 2.0;
        }
    }
    super.contentOffset = anOffset;
}

@end
