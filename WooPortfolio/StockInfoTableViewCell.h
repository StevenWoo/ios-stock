//
//  StockInfoTableViewCell.h
//  WooPortfolio
//
//  Created by Steven Woo on 6/21/18.
//  Copyright © 2018 swoo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StockInfoTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *mSymbol;
@property (weak, nonatomic) IBOutlet UILabel *mPrice;
@property (weak, nonatomic) IBOutlet UILabel *mPercentChange;
@property (weak, nonatomic) IBOutlet UILabel *mName;
@end
