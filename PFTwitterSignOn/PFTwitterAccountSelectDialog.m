//
//  PFTwitterAccountSelectDialog.m
//  PFTwitterSignOnExample
//
//  Created by Jesse Ditson on 1/18/14.
//  Copyright (c) 2014 Prix Fixe. All rights reserved.
//

#import "PFTwitterAccountSelectDialog.h"

static PFTwitterAccountSelectDialog *__currentDialog;

@implementation PFTwitterAccountSelectDialog

+ (void)showSelectDialogInView:(UIView *)view withItems:(NSArray *)items cancelButtonTitle:(NSString *)cancelText confirmBlock:(MultiSelectBlock)confirmBlock cancelBlock:(MultiSelectBlock)cancelBlock
{
    if (__currentDialog) {
        [__currentDialog.dialog dismissWithClickedButtonIndex:[__currentDialog.dialog cancelButtonIndex] animated:NO];
    }
    __currentDialog = [[PFTwitterAccountSelectDialog alloc] initWithInView:view items:items cancelButtonTitle:cancelText confirmBlock:confirmBlock cancelBlock:cancelBlock];
}

- (id)initWithInView:(UIView *)view items:(NSArray *)items cancelButtonTitle:(NSString *)cancelText confirmBlock:(MultiSelectBlock)confirmBlock cancelBlock:(MultiSelectBlock)cancelBlock
{
    if (self = [super init]) {
        _confirmBlock = confirmBlock;
        _cancelBlock = cancelBlock;
        
        _dialog = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
        for (NSString *title in items) {
            [_dialog addButtonWithTitle:title];
        }
        [_dialog addButtonWithTitle:cancelText];
        [_dialog setCancelButtonIndex:items.count];
        [_dialog showInView:view];
    }
    return self;
}

# pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == [_dialog cancelButtonIndex] && _cancelBlock) {
        _cancelBlock(buttonIndex);
    } else if(buttonIndex != [_dialog cancelButtonIndex] && _confirmBlock) {
        _confirmBlock(buttonIndex);
    }
}

@end
