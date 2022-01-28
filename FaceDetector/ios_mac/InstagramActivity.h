//
//  InstagramActivity.h
//
//  Created by Jacob Nielsen 2015
//

#import <UIKit/UIKit.h>

@interface InstagramActivity : UIActivity <UIDocumentInteractionControllerDelegate>

@property (nonatomic, strong) UIImage *imageToShare;
@property (nonatomic, strong) NSString *messageToShare;

@property (nonatomic, strong) UIViewController *viewController;
@property (nonatomic, strong) UIDocumentInteractionController *documentController;

@property (nonatomic) float originX;
@property (nonatomic) float originY;

@end
