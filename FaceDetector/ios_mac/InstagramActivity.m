//
//  InstagramActivity.m
//
//  Created by Jacob Nielsen 2015
//

#import "InstagramActivity.h"

@implementation InstagramActivity

- (NSString *)activityType {
    return @"UIActivityTypePostToInstagram";
}

- (NSString *)activityTitle {
    return @"Instagram";
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"InstagramActivityIcon.png"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    return YES;
}

- (void)performActivity {

    NSData *imageData = UIImageJPEGRepresentation(self.imageToShare, 1.0);
    
    NSString *writePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"instagram.igo"]; // "instagram.ig"
    if (![imageData writeToFile:writePath atomically:YES]) {
        NSLog(@"saving instagram.igo image failed %@", writePath);
        [self activityDidFinish:NO];
        return;
    }
    
    // send it to instagram
    NSURL *fileURL = [NSURL fileURLWithPath:writePath];
    self.documentController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
    self.documentController.delegate = self;
    self.documentController.UTI = @"com.instagram.exclusivegram"; // "com.instagram.photo"
    if (self.messageToShare) [self.documentController setAnnotation:@{@"InstagramCaption" : self.messageToShare}];
    
    // present
    CGRect rect = CGRectMake(self.originX, self.originY, 1, 1);
    [self.documentController presentOpenInMenuFromRect:rect inView:self.viewController.view animated:YES];
}


- (void)documentInteractionController:(UIDocumentInteractionController *)controller didEndSendingToApplication:(NSString *)application {
    [self activityDidFinish:YES];
}

-(void)activityDidFinish:(BOOL)success {
    //NSLog(@"Instagram activity finished");
    NSError *error = nil;
    NSString *writePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"instagram.igo"]; // "instagram.ig"
    if (![[NSFileManager defaultManager] removeItemAtPath:writePath error:&error]) {
        NSLog(@"Error removing file: %@", error);
    }
    [super activityDidFinish:success];
}

@end
