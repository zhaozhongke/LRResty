//
//  RemoteRepositoryExample.m
//  LRResty
//
//  Created by Luke Redpath on 06/08/2010.
//  Copyright 2010 LJR Software Limited. All rights reserved.
//

#import "RemoteRepositoryExample.h"
#import "LRResty.h"
#import "LRRestyResponse+JSON.h"

@implementation GithubUser

@synthesize remoteID, username;
@synthesize fullName;

- (id)initWithUsername:(NSString *)theUsername;
{
  if (self = [super init]) {
    username = [theUsername copy];
  }
  return self;
}

- (id)initWithUsername:(NSString *)theUsername remoteID:(GithubID)theID;
{
  if (self = [super init]) {
    username = [theUsername copy];
    remoteID = theID;
  }
  return self;
}

- (void)dealloc
{
  [username release];
  [super dealloc];
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"<GithubUser id:%d username:%@>", remoteID, username];
}

@end

@implementation RemoteResourceRepository

@synthesize delegate;

- (id)initWithRemoteResource:(LRRestyResource *)aResource;
{
  if (self = [super init]) {
    resource = [aResource retain];
    [resource setClientDelegate:self];
  }
  return self;
}

- (void)dealloc
{
  [resource release];
  [super dealloc];
}

- (void)restyClientWillPerformRequest:(LRRestyClient *)resource
{
  [self.delegate repositoryWillFetchFromResource:self];
}

- (void)restyClientDidPerformRequest:(LRRestyClient *)resource
{
  [self.delegate repositoryDidFetchFromResource:self];
}

@end

@implementation GithubUserRepository

GithubID userIDFromString(NSString *userIDString)
{
  // for some reason the search API returns IDs as user-xxxx
  return [[[userIDString componentsSeparatedByString:@"-"] lastObject] integerValue];
}

- (void)getUserWithUsername:(NSString *)username 
        andYield:(GithubUserRepositoryResultBlock)resultBlock;
{
  [[resource at:[NSString stringWithFormat:@"user/show/%@", username]] get:^(LRRestyResponse *response) {
    NSDictionary *userData = [[response asJSONObject] objectForKey:@"user"];
    GithubUser *user = [[GithubUser alloc] initWithUsername:[userData objectForKey:@"login"] remoteID:[[userData objectForKey:@"id"] integerValue]];
    user.fullName = [userData objectForKey:@"name"];
    resultBlock(user);
    [user release];
  }];
}

- (void)getUsersMatching:(NSString *)searchString
        andYield:(RepositoryCollectionResultBlock)resultBlock;
{
  [[resource at:[NSString stringWithFormat:@"user/search/%@", searchString]] get:^(LRRestyResponse *response) {
    NSMutableArray *users = [NSMutableArray array];
    for (NSDictionary *userData in [[response asJSONObject] objectForKey:@"users"]) {
      GithubUser *user = [[GithubUser alloc] initWithUsername:[userData objectForKey:@"username"] remoteID:userIDFromString([userData objectForKey:@"id"])];
      user.fullName = [userData objectForKey:@"fullname"];
      [users addObject:user];
      [user release];
    }
    resultBlock(users);
  }];
}

@end

