//
//  PFTwitterAccountSelectDialog.h
//  PFTwitterSignOnExample
//
//  Created by Jesse Ditson on 1/18/14.
//  Copyright (c) 2014 Prix Fixe. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^MultiSelectBlock)(NSInteger selectedIndex);

@interface PFTwitterAccountSelectDialog : NSObject <UIActionSheetDelegate>

@property (nonatomic, strong) UIActionSheet *dialog;
@property (nonatomic, copy) MultiSelectBlock confirmBlock;
@property (nonatomic, copy) MultiSelectBlock cancelBlock;

+ (void)showSelectDialogInView:(UIView *)view withItems:(NSArray *)items cancelButtonTitle:(NSString *)cancelText confirmBlock:(MultiSelectBlock)confirmBlock cancelBlock:(MultiSelectBlock)cancelBlock;

@end
