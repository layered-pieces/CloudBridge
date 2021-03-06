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

#import "CBRPersistentObject.h"
#import "CBRCloudBridge.h"
#import "CBREntityDescription.h"

#import <objc/runtime.h>

void class_implementProtocolExtension(Class klass, Protocol *protocol, Class prototype)
{
    assert(class_conformsToProtocol(prototype, protocol));

    unsigned int count = 0;
    Protocol * __unsafe_unretained *childProtocols = protocol_copyProtocolList(protocol, &count);

    for (unsigned int i = 0; i < count; i++) {
        if (childProtocols[i] == @protocol(NSObject)) {
            continue;
        }

        class_implementProtocolExtension(klass, childProtocols[i], prototype);
    }

    free(childProtocols);

    void(^copyMethods)(BOOL isRequiredMethod, BOOL isInstanceMethod) = ^(BOOL isRequiredMethod, BOOL isInstanceMethod) {
        unsigned int count = 0;
        struct objc_method_description *methods = protocol_copyMethodDescriptionList(protocol, isRequiredMethod, isInstanceMethod, &count);

        for (unsigned int i = 0; i < count; i++) {
            if (isInstanceMethod) {
                IMP implementation = class_getMethodImplementation(prototype, methods[i].name);
                assert(implementation);

                class_addMethod(klass, methods[i].name, implementation, methods[i].types);
            } else {
                IMP implementation = class_getMethodImplementation(objc_getMetaClass(class_getName(prototype)), methods[i].name);
                assert(implementation);

                class_addMethod(objc_getMetaClass(class_getName(klass)), methods[i].name, implementation, methods[i].types);
            }
        }
    };

    copyMethods(NO, NO);
    copyMethods(NO, YES);
    copyMethods(YES, NO);
    copyMethods(YES, YES);

    class_addProtocol(klass, protocol);
}

@implementation CBRPersistentObjectPrototype

+ (BOOL)resolveRelationshipForSelector:(SEL)selector inClass:(Class)klass
{
    klass = klass.class; // Google Analytics fix

    assert([klass conformsToProtocol:@protocol(CBRPersistentObject)]);
    if (![klass cloudBridge]) {
        return NO;
    }

    NSString *selectorName = NSStringFromSelector(selector);
    if (![selectorName hasSuffix:@"WithCompletionHandler:"]) {
        return NO;
    }

    if ([selectorName rangeOfString:@":"].location != selectorName.length - 1) {
        return NO;
    }

    // CoreData is creating for the entity SLEntity1 an new subclass SLEntity1_SLEntity1 and KVO an additional NSKeyValueObserving_SLEntity1_SLEntity1
    while (klass != [klass class]) {
        klass = [klass class];
    }

    NSRange range = [selectorName rangeOfString:@"WithCompletionHandler:"];
    NSString *relationship = [selectorName substringToIndex:range.location];

    CBREntityDescription *entityDescription = [klass cloudBridgeEntityDescription];
    CBRRelationshipDescription *relationshipDescription = entityDescription.relationshipsByName[relationship];

    if (!relationshipDescription) {
        return NO;
    }

    BOOL isToMany = relationshipDescription.toMany;
    IMP implementation = imp_implementationWithBlock(^(id<CBRPersistentObject> blockSelf, void(^completionHandler)(id object, NSError *error)) {
        if (isToMany) {
            [blockSelf fetchObjectsForRelationship:relationship withCompletionHandler:completionHandler];
        } else {
            [blockSelf fetchObjectForRelationship:relationship withCompletionHandler:completionHandler];
        }
    });

    return class_addMethod(klass, selector, implementation, "v@:@");
}

#pragma mark - CBRPersistentObject

+ (CBRCloudBridge *)cloudBridge
{
    CBRCloudBridge *cloudBridge = objc_getAssociatedObject(self, @selector(cloudBridge));
    if (cloudBridge) {
        return cloudBridge;
    }

    if (class_getSuperclass(self) == [NSObject class]) {
        return nil;
    }

    return [[self superclass] cloudBridge];
}

+ (void)setCloudBridge:(CBRCloudBridge *)cloudBridge
{
    objc_setAssociatedObject(self, @selector(cloudBridge), cloudBridge, OBJC_ASSOCIATION_RETAIN);
}

- (CBRCloudBridge *)cloudBridge
{
    return [self.class cloudBridge];
}

+ (CBRDatabaseAdapter *)databaseAdapter
{
    return [self cloudBridge].databaseAdapter;
}

- (CBRDatabaseAdapter *)databaseAdapter
{
    return [self cloudBridge].databaseAdapter;
}

+ (CBREntityDescription *)cloudBridgeEntityDescription
{
    return [self cloudBridge].databaseAdapter.entitiesByName[NSStringFromClass([self class])];
}

- (CBREntityDescription *)cloudBridgeEntityDescription
{
    return [self.class cloudBridgeEntityDescription];
}

#pragma mark - CBRPersistentObjectQueryInterface

+ (instancetype)objectWithRemoteIdentifier:(id)identifier
{
    assert(identifier == nil || [identifier conformsToProtocol:@protocol(CBRPersistentIdentifier)]);
    CBREntityDescription *entityDescription = [self cloudBridgeEntityDescription];
    return (id)[[self cloudBridge].databaseAdapter persistentObjectOfType:entityDescription withPrimaryKey:identifier];
}

+ (NSDictionary<id<CBRPersistentIdentifier>, id> *)objectsWithRemoteIdentifiers:(NSArray<id<CBRPersistentIdentifier>> *)identifiers
{
    CBREntityDescription *entityDescription = [self cloudBridgeEntityDescription];
    NSString *attribute = [[self cloudBridge].cloudConnection.objectTransformer primaryKeyOfEntitiyDescription:entityDescription];
    NSParameterAssert(attribute);

    return [[self cloudBridge].databaseAdapter indexedObjectsOfType:entityDescription withValues:[NSSet setWithArray:identifiers] forAttribute:attribute];
}

+ (instancetype)newCloudBrideObject
{
    CBREntityDescription *entityDescription = [self cloudBridgeEntityDescription];
    return [[self cloudBridge].databaseAdapter newMutablePersistentObjectOfType:entityDescription];
}

+ (void)fetchObjectsMatchingPredicate:(NSPredicate *)predicate
                withCompletionHandler:(void(^)(NSArray *fetchedObjects, NSError *error))completionHandler
{
    Class class = self;
    while (class != [class class]) {
        class = [class class];
    }

    [self.cloudBridge fetchPersistentObjectsOfClass:class withPredicate:predicate completionHandler:completionHandler];
}

- (void)createWithCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler
{
    [self.cloudBridge createPersistentObject:self withCompletionHandler:completionHandler];
}

- (void)reloadWithCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler
{
    [self.cloudBridge reloadPersistentObject:self withCompletionHandler:completionHandler];
}

- (void)saveWithCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler
{
    [self.cloudBridge savePersistentObject:self withCompletionHandler:completionHandler];
}

- (void)deleteWithCompletionHandler:(void(^)(NSError *error))completionHandler
{
    [self.cloudBridge deletePersistentObject:self withCompletionHandler:completionHandler];
}

#pragma mark - CBRPersistentObjectSubclassHooks

- (void)awakeFromCloudFetch
{

}

+ (id<CBRCloudObject>)prepareForUpdateWithCloudObject:(id<CBRCloudObject>)cloudObject
{
    return cloudObject;
}

- (void)prepareForUpdateWithCloudObject:(id<CBRCloudObject>)cloudObject
{

}

- (void)finalizeUpdateWithCloudObject:(id<CBRCloudObject>)cloudObject
{

}

- (id<CBRCloudObject>)finalizeCloudObject:(id<CBRCloudObject>)cloudObject
{
    return cloudObject;
}

- (void)setCloudValue:(id)value forKey:(NSString *)key fromCloudObject:(id<CBRCloudObject>)cloudObject
{
    [self setValue:value forKey:key];
}

- (id)cloudValueForKey:(NSString *)key
{
    return [self valueForKey:key];
}

#pragma mark - Convenience API

- (id<CBRCloudObject>)cloudObjectRepresentation
{
    return [self.cloudBridge.cloudConnection.objectTransformer cloudObjectFromPersistentObject:self];
}

- (void)fetchObjectForRelationship:(NSString *)relationship withCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler
{
    __assert_unused CBRRelationshipDescription *relationshipDescription = self.cloudBridgeEntityDescription.relationshipsByName[relationship];
    NSParameterAssert(relationshipDescription);
    NSParameterAssert(!relationshipDescription.toMany);

    [self fetchObjectsForRelationship:relationship withCompletionHandler:^(NSArray *objects, NSError *error) {
        if (completionHandler) {
            completionHandler(objects.lastObject, error);
        }
    }];
}

- (void)fetchObjectsForRelationship:(NSString *)relationship withCompletionHandler:(void(^)(NSArray *objects, NSError *error))completionHandler
{
    CBRRelationshipDescription *relationshipDescription = self.cloudBridgeEntityDescription.relationshipsByName[relationship];
    NSParameterAssert(relationshipDescription);
    NSParameterAssert(relationshipDescription.inverseRelationship);
    NSParameterAssert(!relationshipDescription.inverseRelationship.toMany);

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", relationshipDescription.inverseRelationship.name, self];
    [self.cloudBridge fetchPersistentObjectsOfClass:NSClassFromString(relationshipDescription.inverseRelationship.entity.name)
                                      withPredicate:predicate
                                  completionHandler:completionHandler];
}

+ (instancetype)persistentObjectFromCloudObject:(id<CBRCloudObject>)cloudObject
{
    CBREntityDescription *entity = [self cloudBridgeEntityDescription];
    return (id)[[self cloudBridge].cloudConnection.objectTransformer persistentObjectFromCloudObject:cloudObject forEntity:entity];
}

@end
