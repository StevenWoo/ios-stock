//
//  ViewController.m
//  WooPortfolio
//
//  Created by Steven Woo on 6/21/18.
//  Copyright © 2018 swoo. All rights reserved.
//

#import "PortfolioTableViewController.h"
#import "StockInfoTableViewCell.h"

@interface PortfolioTableViewController () <UITableViewDataSource, UITableViewDelegate>
@end

@implementation PortfolioTableViewController
NSMutableDictionary *mPortfolioBySymbol;
NSMutableArray *mColors;

NSString *cellId = @"StockInfoV2";
NSString *mFormatUrlApiBatchQuote = @"https://api.iextrading.com/1.0/stock/market/batch?symbols=%@&types=quote";
NSString *mFormatUrlApiQuote = @"https://api.iextrading.com/1.0/stock/%@/quote";
NSString *KEY_PORTFOLIO = @"portfolio.v1";

- (void)setColors {
    if( mColors != nil ){
        if( mPortfolioBySymbol != nil ){
            NSUInteger count = [mPortfolioBySymbol count];
            [mColors removeAllObjects];
            if( count != 0 ){
                NSMutableArray *allKeys = [[mPortfolioBySymbol allKeys]mutableCopy];
                [allKeys sortUsingComparator:^NSComparisonResult(id  obj1, id obj2) {
                    NSString *key1 = obj1;
                    NSString *key2 = obj2;
                    return [key1 caseInsensitiveCompare:key2];
                }];

                for(NSString *key in allKeys){
                    NSDictionary *dictStock = [mPortfolioBySymbol objectForKey:key];
                    NSNumber *change = [dictStock objectForKey:@"changePercent"];
                    double percentChange = [change doubleValue] * 100.0;
                    if( [key isEqualToString:@"sjnk"]){
                        NSLog(@"hey");
                    }
                    UIColor *newColor = nil;
                    if( percentChange < -0.001 ){
                        newColor= [UIColor colorWithRed:256.0f/256.0f green:0.35f blue:0.35f alpha:1.0f];
                    }
                    else if( percentChange > 0.001 ){
                        newColor= [UIColor colorWithRed:0.35f green:256.0f/256.0f blue:0.35f alpha:1.0f];
                    }
                    else{
                        newColor = [UIColor colorWithWhite:1.0f alpha:1.0f];
                    }
                    [mColors addObject:newColor];
                }
            }
        }
    }
}
- (void)getDataFromServer {
//    /stock/market/batch?symbols=aapl,fb,tsla&types=quote,news,chart&range=1m&last=5
    if( mPortfolioBySymbol != nil && [mPortfolioBySymbol count] > 0){
        NSArray *allKeys = [mPortfolioBySymbol allKeys];
        NSString *symbolParameter = @"";
        int count = 0;
        for(NSString *key in allKeys){
            if( count != 0 ){
                symbolParameter = [symbolParameter stringByAppendingString:@","];
            }
            symbolParameter = [symbolParameter stringByAppendingString:key];
            ++count;
        }
        
        _mLabelStatus.text = @"getting data from server...";
        [self batchGetRequest:symbolParameter withHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            //convert data to json
            if( error == nil ){
                NSJSONSerialization *jsonThing = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                if( jsonThing != nil ){
                    NSLog(@"%@", jsonThing);
                    NSArray *allKeys = [(NSDictionary*)jsonThing allKeys];
                    for(NSString *symbol in allKeys){
                        NSDictionary *subDictionary = [(NSDictionary*)jsonThing objectForKey:symbol];
                        NSDictionary *quoteDictionary = [subDictionary objectForKey:@"quote"];
                        [mPortfolioBySymbol setObject:quoteDictionary forKey:[symbol lowercaseString]];
                    }
//                    NSString *symbol = [jsonThing valueForKey:@"symbol"];
//                    [mPortfolioBySymbol setObject:jsonThing forKey:symbol];
                    NSLog(@"got stuff from server");
                    dispatch_queue_t mainQueue = dispatch_get_main_queue();
                    dispatch_async(mainQueue, ^{
                        self.mLabelStatus.text = @"";
                        [self saveData];
                        [self setColors];
                        [self.tableView reloadData];
                    });
                }
            }
            else {
                NSLog(@"error :%@", error);
                dispatch_queue_t mainQueue = dispatch_get_main_queue();
                dispatch_async(mainQueue, ^{
                    self.mLabelStatus.text = [NSString stringWithFormat:@"%@", error ];
                });

            }
        }];

    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    if(_mLabelStatus != nil){
        _mLabelStatus.text = @"";
    }
    // Do any additional setup after loading the view, typically from a nib.
    [self.tableView registerNib:[UINib nibWithNibName:@"StockInfoTableViewCell" bundle:nil] forCellReuseIdentifier:cellId];
    mPortfolioBySymbol = [[NSMutableDictionary alloc]init];
    mColors = [[NSMutableArray alloc]init];
    [self loadData];
    [self setColors];
    [self getDataFromServer];
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl]; //assumes tableView is @property
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) saveData {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if( mPortfolioBySymbol != nil ){
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:mPortfolioBySymbol];
        [defaults setObject:data forKey:KEY_PORTFOLIO];
    }
    [defaults synchronize];
}
- (void) loadData {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *serializedData = [defaults objectForKey:KEY_PORTFOLIO];
    if( serializedData != nil ){
        NSDictionary * someData = [NSKeyedUnarchiver unarchiveObjectWithData:serializedData];
        [mPortfolioBySymbol addEntriesFromDictionary:someData];
    }

}
//
-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    StockInfoTableViewCell *cell = (StockInfoTableViewCell*)[tableView dequeueReusableCellWithIdentifier:cellId];
    if( cell == nil ){
        cell = [[StockInfoTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    }
    if( indexPath.row < [mPortfolioBySymbol count]){
        NSMutableArray *allKeys = [[mPortfolioBySymbol allKeys] mutableCopy];
        [allKeys sortUsingComparator:^NSComparisonResult(id  obj1, id obj2) {
            NSString *key1 = obj1;
            NSString *key2 = obj2;
            return [key1 caseInsensitiveCompare:key2];
        }];
        int count = 0;
         for(NSString *key in allKeys) {
             if( count == indexPath.row){
                 NSDictionary *dictObject = [mPortfolioBySymbol objectForKey:key];
                 if( dictObject != nil ){
                     cell.mSymbol.text = [dictObject objectForKey:@"symbol"];
                     cell.mName.text = [dictObject objectForKey:@"companyName"];
                     cell.mPrice.text = [NSString stringWithFormat:@"%@", [dictObject objectForKey:@"latestPrice"]];
                     NSNumber *change = [dictObject objectForKey:@"changePercent"];
                     double percentChange = [change doubleValue] * 100.0;
                     cell.mPercentChange.text = [NSString stringWithFormat:@"%2.2f%%", percentChange];
                     if( [mColors count] >= indexPath.row){
                         [cell setBackgroundColor:[mColors objectAtIndex:indexPath.row]];
                     }
                 }
             }
             ++count;

         }
    }
    return cell;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [mPortfolioBySymbol count];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(void)showAlert {
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle: @"Could not find that symbol"
                                                                              message: @"Please check your spelling and try again"
                                                                       preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    }]];
    [self presentViewController:alertController animated:YES completion:nil];

}
-(void)getQuote:(NSString*)symbol {
    BOOL test = true;
    if( test == true ){
        [self getSingleQuote:symbol withHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            //convert data to json
            if( error == nil ){
                NSJSONSerialization *jsonThing = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                if( jsonThing != nil ){
                    NSLog(@"%@", jsonThing);
                    NSString *symbol = [[jsonThing valueForKey:@"symbol"] lowercaseString];
                    [mPortfolioBySymbol setObject:jsonThing forKey:symbol];
                    dispatch_queue_t mainQueue = dispatch_get_main_queue();
                    dispatch_async(mainQueue, ^{
                        [self saveData];
                        [self setColors];
                        [self.tableView reloadData];
                    });
                }
                else {
                    NSString *testString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    NSLog(@"got response of %@", testString);
                    testString = nil;
                    [self showAlert];
                }
            }
            else {
                NSLog(@"error :%@", error);
            }
        }];
    }

}
-(IBAction)didSelectAddButton:(id)sender {
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle: @"Add stock symbol"
                                                                              message: @"Input symbol"
                                                                       preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Symbol";
        textField.textColor = [UIColor blueColor];
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.borderStyle = UITextBorderStyleRoundedRect;
    }];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSArray * textfields = alertController.textFields;
        UITextField * namefield = textfields[0];
        NSLog(@"%@",namefield.text);
        NSString *lowerCaseSymbol = [namefield.text lowercaseString];
        NSDictionary *currentValue =  [mPortfolioBySymbol objectForKey:lowerCaseSymbol];
        if(currentValue == nil || [currentValue count] == 0 ){
            // get quote
            [self getQuote:lowerCaseSymbol];
        }
        
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

-(void)dealloc {
    mPortfolioBySymbol = nil;
    mColors = nil;
}



-(void)getSingleQuote:(NSString *)symbol withHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))ourBlock {
    
    NSString *urlString = [NSString stringWithFormat: mFormatUrlApiQuote, symbol];

    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:ourBlock] resume];
}

-(void)batchGetRequest:(NSString *)symbols withHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))ourBlock {
    
    NSString *urlString = [NSString stringWithFormat: mFormatUrlApiBatchQuote, symbols];
    
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:ourBlock] resume];
}

-(void)refresh {
    [self.refreshControl beginRefreshing];
    NSLog(@"hello");
    [self.refreshControl endRefreshing];
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSMutableArray *allKeys = [[mPortfolioBySymbol allKeys] mutableCopy];
        [allKeys sortUsingComparator:^NSComparisonResult(id  obj1, id obj2) {
            NSString *key1 = obj1;
            NSString *key2 = obj2;
            return [key1 caseInsensitiveCompare:key2];
        }];
        int count = 0;
        for(NSString *key in allKeys) {
            if(count == indexPath.row){
                [mPortfolioBySymbol removeObjectForKey:key];
                [self setColors];
                [self.tableView reloadData];
                return;
            }
            ++count;
        }
    }
}
@end
