#import "PURTableViewController.h"
#import "PURAppDelegate.h"
#import "AKSlidecks.h"
@implementation PURAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	PURTableViewController *tvc = [[PURTableViewController alloc] initWithStyle:UITableViewStylePlain];
	AKSlidecks *slidecks = [[AKSlidecks alloc] initWithRootViewController:tvc itemsCount:0];
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = slidecks;
	[self.window makeKeyAndVisible];
    return YES;
}
@end
