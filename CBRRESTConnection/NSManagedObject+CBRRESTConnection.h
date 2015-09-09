/**
 CBRRESTConnection
 Copyright (c) 2014 Oliver Letterer <oliver.letterer@gmail.com>, Sparrow-Labs

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

@import CoreData;



@interface NSManagedObject (CBRRESTConnection)

+ (instancetype)objectWithRemoteIdentifier:(id)identifier inManagedObjectContext:(NSManagedObjectContext *)context;

+ (void)fetchObjectFromPath:(NSString *)path withCompletionHandler:(void (^)(id managedObject, NSError *error))completionHandler;
+ (void)fetchObjectsFromPath:(NSString *)path withCompletionHandler:(void (^)(NSArray *fetchedObjects, NSError *error))completionHandler;

- (void)createToPath:(NSString *)path withCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler;
- (void)reloadFromPath:(NSString *)path withCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler;
- (void)saveToPath:(NSString *)path withCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler;
- (void)deleteToPath:(NSString *)path withCompletionHandler:(void(^)(NSError *error))completionHandler;

@end