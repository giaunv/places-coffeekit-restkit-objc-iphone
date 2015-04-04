//
//  MasterViewController.m
//  coffeekit
//
//  Created by giaunv on 4/3/15.
//  Copyright (c) 2015 366. All rights reserved.
//

#import <RestKit/RestKit.h>
#import "MasterViewController.h"
#import "Venue.h"
#import "Location.h"
#import "VenueCell.h"
#import "Stats.h"

#define kCLIENTID @"RFZ3ACGIIO0ZOALYPIGJNC1IQOAWXMXVCVO1SAUTDQKQXZIL"
#define kCLIENTSECRET @"BSIVZ20I1W2OKVFZ5YCN2CC5TGDBXYXGDVLBFTYNUUISQV21"

@interface MasterViewController ()
@property (nonatomic, strong) NSArray* venues;
@end

@implementation MasterViewController

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureRestKit];
    [self loadVenues];
}

- (void)configureRestKit {
    // initialize AFNetworking HTTPClient
    NSURL *baseURL = [NSURL URLWithString:@"https://api.foursquare.com"];
    AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:baseURL];
    
    // initialize RestKit
    RKObjectManager *objectManager = [[RKObjectManager alloc] initWithHTTPClient:client];
    
    // setup object mappings
    RKObjectMapping *venueMapping = [RKObjectMapping mappingForClass:[Venue class]];
    [venueMapping addAttributeMappingsFromArray:@[@"name"]];
    
    // register mappings with the provider using a response descriptor
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:venueMapping method:RKRequestMethodGET pathPattern:@"/v2/venues/search" keyPath:@"response.venues" statusCodes:[NSIndexSet indexSetWithIndex:200]];
    
    [objectManager addResponseDescriptor:responseDescriptor];
    
    // define location object mapping
    RKObjectMapping *locationMapping = [RKObjectMapping mappingForClass:[Location class]];
    [locationMapping addAttributeMappingsFromArray:@[@"address",@"city",@"county",@"crossStreet",@"postalCode",@"state",@"distance",@"lat",@"long"]];
    
    // define relationship mapping
    [venueMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"location" toKeyPath:@"location" withMapping:locationMapping]];
    
    RKObjectMapping *statsMapping = [RKObjectMapping mappingForClass:[Stats class]];
    [statsMapping addAttributeMappingsFromDictionary:@{@"checkinsCount": @"checkins", @"tipCount": @"tips", @"usersCount": @"users"}];
    
    [venueMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"stats" toKeyPath:@"stats" withMapping:statsMapping]];
}

- (void)loadVenues{
    NSString *latLon = @"37.33,-122.03"; // approximate latLon of The Mothership (a.k.a Apple headquarters)
    NSString *clientID = kCLIENTID;
    NSString *clientSecret = kCLIENTSECRET;
    
    NSDictionary *queryParams = @{@"ll": latLon,
                                  @"client_id": clientID,
                                  @"client_secret": clientSecret,
                                  @"categoryId": @"4bf58dd8d48988d1e0931735",
                                  @"v": @"20140118"
                                  };
    
    [[RKObjectManager sharedManager] getObjectsAtPath:@"v2/venues/search" parameters:queryParams success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        _venues = mappingResult.array;
        [self.tableView reloadData];
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        NSLog(@"What to do mean by 'there is no coffee?': %@", error);
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Segues

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _venues.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    VenueCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VenueCell" forIndexPath:indexPath];
    
    Venue *venue = _venues[indexPath.row];
    cell.nameLabel.text = venue.name;
    cell.distanceLabel.text = [NSString stringWithFormat:@"%.0fm", venue.location.distance.floatValue];
    cell.checkinsLabel.text = [NSString stringWithFormat:@"%d checkins", venue.stats.checkins.intValue];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

@end
