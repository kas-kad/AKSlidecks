#import <UIKit/UIKit.h>
#import "AKSlidecks.h"

@interface PURTableViewController : UITableViewController <AKSlidecksCapable>
@property (nonatomic, strong) NSString *parentItem;
@property (nonatomic, weak) AKSlidecks *slidecksViewController;
@property (nonatomic, strong) AKSlidecksItem *slidecksItem;
-(CGFloat)slidecksEstimatedWidth;
-(BOOL)slidecksSlidingEnabled;
@end
