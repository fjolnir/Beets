#import <UIKit/UIKit.h>

@interface AppDelegate : NSObject <UIApplicationDelegate>
@property(nonatomic, retain) UIWindow *window;
@end
@implementation AppDelegate
@end

int main(int argc, char * argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, @"AppDelegate");
    }
}
