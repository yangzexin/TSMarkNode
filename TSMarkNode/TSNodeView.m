//
//  TSNodeView.m
//  TSMarkNode
//
//  Created by yangzexin on 2020/5/14.
//  Copyright © 2020 yangzexin. All rights reserved.
//

#import "TSNodeView.h"
#import "TSNode.h"
#import "TSNode+LayoutAddition.h"

@interface TSNodeView () <UITextViewDelegate>

@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UIView *draggingIndicator;
@property (nonatomic, strong) CABasicAnimation *scaleAnimation;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, assign) CGSize lastEditTextSize;
@property (nonatomic, strong) UIView *maskView;

@end

@implementation TSNodeView

- (void)initCompat {
    [super initCompat];
    self.backgroundColor = [UIColor clearColor];
//    self.backgroundColor = [UIColor sf_colorWithRed:255 green:0 blue:0 alpha:50];
    self.dragStateDisplayable = YES;
    self.style = [[TSDefaultMindViewStyle shared] styleForNode:nil];
    
    self.scaleAnimation = ({
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        animation.fromValue = @1.0f;
        animation.toValue = @1.05f;
        animation.duration = .17f;
        animation.autoreverses = YES;
        animation.repeatCount = HUGE_VALF;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        animation;
    });
    
    self.backgroundView = ({
        UIView *view = [UIView new];
        view.layer.masksToBounds = YES;
        [self addSubview:view];
        view;
    });
    
    self.label = ({
        UILabel *label = [UILabel new];
        label.numberOfLines = 0;
        [label setBackgroundColor:[UIColor clearColor]];
        label.textAlignment = NSTextAlignmentLeft;
        [self addSubview:label];
        label;
    });
    
    self.draggingIndicator = ({
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 80, 20)];
        view.backgroundColor = [UIColor sf_colorWithRed:227 green:227 blue:227 alpha:100];
        view.layer.masksToBounds = YES;
        [self addSubview:view];
        view;
    });
    
    __weak typeof(self) weakSelf = self;
    [SFObserveProperty(self, node) onChange:^(TSNode *value) {
        __strong typeof(self) self = weakSelf;
        self.label.text = value.title;
        
        [self _updateDraggableDisplayableState];
        [self _updateSubviewStates];
    }];
    
    [SFTrackProperty(self, dragStateDisplayable) onChange:^(id value) {
        __strong typeof(self) self = weakSelf;
        [self _updateDraggableDisplayableState];
    }];
    
    [SFObserveProperty(self, editing) onChange:^(NSNumber *value) {
        __strong typeof(self) self = weakSelf;
        if (self.textView == nil) {
            self.textView = ({
                UITextView *view = [[UITextView alloc] initWithFrame:self.label.frame];
                view.backgroundColor = [UIColor clearColor];
                view.textContainer.lineFragmentPadding = 0;
                view.textContainerInset = UIEdgeInsetsZero;
                view.delegate = self;
                view.returnKeyType = UIReturnKeyDone;
                [self addSubview:view];
                view;
            });
        }
        self.label.hidden = self.editing;
        
        self.textView.text = self.label.text;
        self.textView.hidden = !self.editing;
        if ([value boolValue]) {
            self.textView.frame = self.label.frame;
            self.textView.font = self.label.font;
            self.textView.textColor = self.label.textColor;
            self.textView.textAlignment = self.label.textAlignment;
            [self.textView becomeFirstResponder];
        }
    }];
    
    [SFObserveProperty(self, selected) onChange:^(id value) {
        __strong typeof(self) self = weakSelf;
        [self _initMaskView];
        self.maskView.frame = self.backgroundView.frame;
        self.maskView.hidden = !self.selected;
    }];
}

- (void)_initMaskView {
    if (self.maskView == nil) {
        self.maskView = [[UIView alloc] initWithFrame:CGRectZero];
        self.maskView.backgroundColor = [UIColor blueColor];
        self.maskView.alpha = .27f;
        [self addSubview:self.maskView];
    }
}

- (void)_updateSubviewStates {
    self.backgroundView.backgroundColor = self.style.backgroundColor;
    self.backgroundView.layer.borderWidth = self.style.borderWidth;
    self.backgroundView.layer.cornerRadius = self.style.cornerRadius;
    self.backgroundView.layer.borderColor = self.style.borderColor.CGColor;
    
    self.maskView.layer.borderWidth = self.style.borderWidth;
    self.maskView.layer.cornerRadius = self.style.cornerRadius;
    self.maskView.layer.borderColor = self.style.borderColor.CGColor;
    
    self.draggingIndicator.layer.cornerRadius = self.style.cornerRadius;
    
    self.label.frame = CGRectMake(self.titleFrame.origin.x + self.displayRect.origin.x, self.titleFrame.origin.y + self.displayRect.origin.y, self.titleFrame.size.width, self.titleFrame.size.height);
    self.label.textColor = self.style.textColor;
    self.label.font = [UIFont systemFontOfSize:self.style.fontSize];
    self.label.hidden = self.editing;
    
    NSUInteger alignment = self.style.alignment;
    if (alignment == TSNodeContentAlignmentLeft) {
        self.label.textAlignment = NSTextAlignmentLeft;
    } else if (alignment == TSNodeContentAlignmentRight) {
        self.label.textAlignment = NSTextAlignmentRight;
    } else if (alignment == TSNodeContentAlignmentCenter) {
        self.label.textAlignment = NSTextAlignmentCenter;
    }
    
    if (self.textView && !self.textView.hidden) {
        self.textView.frame = self.label.frame;
        
        [self.textView scrollRangeToVisible:NSMakeRange(0, 0)];
    }
    
    self.backgroundView.frame = self.displayRect;
    
    self.maskView.frame = self.backgroundView.frame;
    
    [self didChangeBackgroundViewFrame];
}

- (void)didChangeBackgroundViewFrame {
//    self.alpha = .50f;
}

- (void)_updateDraggableDisplayableState {
    if (self.dragStateDisplayable) {
        BOOL dragging = [self.node isDragging];
        self.label.hidden = dragging;
        self.backgroundView.hidden = dragging;
        self.draggingIndicator.hidden = !dragging;
    } else {
        self.label.hidden = NO;
        self.backgroundView.hidden = NO;
        self.draggingIndicator.hidden = YES;
    }
    if ([self.node isTempAdd]) {
        [self.layer removeAnimationForKey:@"scaleAnim"];
        [self.layer addAnimation:self.scaleAnimation forKey:@"scaleAnim"];
    } else {
        [self.layer removeAnimationForKey:@"scaleAnim"];
    }
}

- (CGSize)_calNodeTitleSizeWithText:(NSString *)text {
    CGSize textSize = [text sf_sizeWithFont:[UIFont systemFontOfSize:self.style.fontSize] constrainedToSize:CGSizeMake(self.style.maxWidth, MAXFLOAT)];
    
    return textSize;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self _updateSubviewStates];
    
    self.draggingIndicator.frame = self.backgroundView.frame;
}

- (void)sizeToFit {
    CGRect frame = self.frame;
    frame.size = self.displayRect.size;
    self.frame = frame;
}

- (void)widthToFit {
    CGRect frame = self.frame;
    frame.size = CGSizeMake(self.displayRect.size.width, frame.size.height);
    self.frame = frame;
}

- (BOOL)isPointInView:(CGPoint)point {
    return [self.backgroundView sf_isPointInView:point];
}

- (CGRect)visibleRect {
    return self.backgroundView.frame;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    self.lastEditTextSize = [self _calNodeTitleSizeWithText:textView.text];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if ([self.delegate respondsToSelector:@selector(mindNodeView:finishEditingNode:text:)]) {
        [self.delegate mindNodeView:self finishEditingNode:self.node text:textView.text];
    }
}

- (void)textViewDidChange:(UITextView *)textView {
    CGSize size = [self _calNodeTitleSizeWithText:textView.text];
    if (size.height != self.lastEditTextSize.height) {
        if ([self.delegate respondsToSelector:@selector(mindNodeView:willChangeNode:text:)]) {
            [self.delegate mindNodeView:self willChangeNode:self.node text:textView.text];
        }
    }
    self.lastEditTextSize = size;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }

    return YES;
}

@end

@interface TSSimpleNodeView ()

@property (nonatomic, strong) UIView *lineView;

@end

@implementation TSSimpleNodeView

- (void)initCompat {
    [super initCompat];
    self.label.textColor = [UIColor blackColor];
}

- (void)_updateSubviewStates {
    [super _updateSubviewStates];
//    self.backgroundView.backgroundColor = [UIColor clearColor];
    self.backgroundView.layer.cornerRadius = 0;
    self.draggingIndicator.layer.cornerRadius = 0;
    self.maskView.layer.cornerRadius = 0;
    
    self.draggingIndicator.layer.borderWidth = 0;
    self.backgroundView.layer.borderWidth = 0;
    self.maskView.layer.borderWidth = 0;
}

@end
