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

#import <Realm/Realm.h>
#import <Foundation/Foundation.h>
#import <CoreData/NSFetchRequest.h>



NS_ASSUME_NONNULL_BEGIN

NS_REQUIRES_PROPERTY_DEFINITIONS
@interface CBRRealmObject : RLMObject

+ (NSDictionary<NSString *, NSString *> *)userInfo;
+ (NSDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *)propertyUserInfo;

+ (void)initialize NS_REQUIRES_SUPER;
+ (nullable NSArray<NSString *> *)ignoredProperties NS_REQUIRES_SUPER;

+ (nullable NSArray<NSString *> *)transformableProperties;
+ (nullable NSArray<NSString *> *)primitiveProperties;

- (nullable id)primitiveValueForKey:(NSString *)key;
- (void)setPrimitiveValue:(nullable id)value forKey:(NSString *)key;

@end



@interface CBRRealmObject (NSFetchRequestResult) <NSFetchRequestResult>
@end

NS_ASSUME_NONNULL_END
