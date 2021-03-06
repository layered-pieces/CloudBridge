/**
 CloudBridge
 Copyright (c) 2018 Layered Pieces gUG

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import <CloudBridge/CBRCloudBridge.h>
#import <CloudBridge/CBROfflineCapablePersistentObject.h>
#import <CloudBridge/CBROfflineCapableCloudConnection.h>
#import <CloudBridge/CBRPersistentStoreInterface.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Entities which should benifit from the offline mode must conform to the `CBROfflineCapablePersistentObject` protocol.
 */
__attribute__((objc_subclassing_restricted))
@interface CBROfflineCapableCloudBridge : CBRCloudBridge

@property (nonatomic, readonly) BOOL isRunningInOfflineMode;
- (void)enableOfflineMode;

@property (nonatomic, readonly) BOOL isReenablingOnlineMode;
- (void)reenableOnlineModeWithCompletionHandler:(void(^_Nullable)(NSError * _Nullable error))completionHandler;

@property (nonatomic, readonly) id<CBROfflineCapableCloudConnection> cloudConnection;

- (instancetype)init NS_DESIGNATED_INITIALIZER UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithCloudConnection:(id<CBROfflineCapableCloudConnection>)cloudConnection
                        interface:(id<CBRPersistentStoreInterface>)interface
                   threadingEnvironment:(CBRThreadingEnvironment *)threadingEnvironment
 NS_DESIGNATED_INITIALIZER;

- (void)createPersistentObject:(id<CBROfflineCapablePersistentObject>)persistentObject
                  withUserInfo:(nullable NSDictionary *)userInfo
             completionHandler:(void(^_Nullable)(id _Nullable persistentObject, NSError * _Nullable error))completionHandler;

- (void)savePersistentObject:(id<CBROfflineCapablePersistentObject>)persistentObject
                withUserInfo:(nullable NSDictionary *)userInfo
           completionHandler:(void(^_Nullable)(id _Nullable persistentObject, NSError * _Nullable error))completionHandler;

- (void)deletePersistentObject:(id<CBROfflineCapablePersistentObject>)persistentObject
                  withUserInfo:(nullable NSDictionary *)userInfo
             completionHandler:(void(^_Nullable)(NSError * _Nullable error))completionHandler;

@end

NS_ASSUME_NONNULL_END
