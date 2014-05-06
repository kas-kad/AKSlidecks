#import "PURTableViewController.h"
#define ITEMS_CNT 20
@interface PURTableViewController ()
{
	NSArray *_items;
}
@end

@implementation PURTableViewController

-(CGFloat)slidecksEstimatedWidth{
	return 320.0f;
}
-(BOOL)slidecksSlidingEnabled{
	return self.slidecksViewController.rootViewController != self;
}
-(void)viewDidLoad{
	[super viewDidLoad];
	self.navigationItem.title = _parentItem ? _parentItem : @"Root";
	self.edgesForExtendedLayout = UIRectEdgeNone;
	
	NSMutableArray *mutable = [NSMutableArray array];
	for (int i = 1; i<=ITEMS_CNT; i++){
		if (_parentItem)
			[mutable addObject:[NSString stringWithFormat:@"%@.%i", _parentItem, i ]];
		else
			[mutable addObject:[NSString stringWithFormat:@"%i", i ]];
	}
	_items = [NSArray arrayWithArray:mutable];
}
-(void)viewWillAppear:(BOOL)animated{
	[super viewWillAppear:animated];
	[self.tableView reloadData];
}
-(void)setParentItem:(NSString *)parentItem{
	_parentItem = parentItem;
}
#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _items.count;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	PURTableViewController *tvc = [[PURTableViewController alloc] initWithStyle:UITableViewStylePlain];
	tvc.parentItem = _items[indexPath.row];
	[self.slidecksViewController presentViewController:tvc from:self animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CELLID"];
	if (!cell){
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CELLID"];
	}
    cell.textLabel.text = _items[indexPath.row];
    return cell;
}


@end
