////////////////////////////////////////////////////////////////////////////////
//
//  TYPHOON FRAMEWORK
//  Copyright 2014, Jasper Blues & Contributors
//  All Rights Reserved.
//
//  NOTICE: The authors permit you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////



#import <objc/runtime.h>
#import "TyphoonAssembly.h"
#import "TyphoonDefinition.h"
#import "TyphoonComponentFactory.h"
#import "TyphoonAssemblySelectorAdviser.h"
#import "TyphoonAssembly+TyphoonAssemblyFriend.h"
#import "TyphoonAssemblyAdviser.h"
#import "TyphoonAssemblyDefinitionBuilder.h"
#import "TyphoonCollaboratingAssemblyPropertyEnumerator.h"
#import "TyphoonCollaboratingAssemblyProxy.h"
#import "TyphoonRuntimeArguments.h"
#import "TyphoonObjectWithCustomInjection.h"
#import "TyphoonInjectionByComponentFactory.h"

static NSMutableArray *reservedSelectorsAsStrings;

@interface TyphoonAssembly () <TyphoonObjectWithCustomInjection>

@property(readwrite) NSSet *definitionSelectors;

@property(readonly) TyphoonAssemblyAdviser *adviser;

@end

@implementation TyphoonAssembly
{
    TyphoonAssemblyDefinitionBuilder *_definitionBuilder;
}


/* ====================================================================================================================================== */
#pragma mark - Class Methods

+ (TyphoonAssembly *)assembly
{
    TyphoonAssembly *assembly = [[self alloc] init];
    [assembly resolveCollaboratingAssemblies];
    return assembly;
}

+ (instancetype)defaultAssembly
{
    return (TyphoonAssembly *) [TyphoonComponentFactory defaultFactory];
}

+ (void)load
{
    [self reserveSelectors];
}

+ (void)reserveSelectors;
{
    reservedSelectorsAsStrings = [[NSMutableArray alloc] init];

    [self markSelectorReserved:@selector(init)];
    [self markSelectorReserved:@selector(definitions)];
    [self markSelectorReserved:@selector(prepareForUse)];
    [self markSelectorReservedFromString:@".cxx_destruct"];
    [self markSelectorReserved:@selector(defaultAssembly)];
    [self markSelectorReserved:@selector(asFactory)];
    [self markSelectorReserved:@selector(resolveCollaboratingAssemblies)];
}

+ (void)markSelectorReserved:(SEL)selector
{
    [self markSelectorReservedFromString:NSStringFromSelector(selector)];
}

+ (void)markSelectorReservedFromString:(NSString *)stringFromSelector
{
    [reservedSelectorsAsStrings addObject:stringFromSelector];
}

/* ====================================================================================================================================== */
#pragma mark - Instance Method Resolution
// handle definition method calls, mapping [self definitionA] to [self->_definitionBuilder builtDefinitionForKey:@"definitionA"]
+ (BOOL)resolveInstanceMethod:(SEL)sel
{
    if ([self shouldProvideDynamicImplementationFor:sel]) {
        [self provideDynamicImplementationToConstructDefinitionForSEL:sel];
        return YES;
    }

    return [super resolveInstanceMethod:sel];
}

+ (BOOL)shouldProvideDynamicImplementationFor:(SEL)sel;
{
    return ([self selectorCorrespondsToDefinitionMethod:sel] && [TyphoonAssemblySelectorAdviser selectorIsAdvised:sel]);
}

+ (BOOL)selectorCorrespondsToDefinitionMethod:(SEL)sel
{
    return ![self selectorReservedOrPropertySetter:sel];
}

+ (BOOL)selectorReservedOrPropertySetter:(SEL)selector
{
    return [self selectorIsReserved:selector] || [self selectorIsPropertySetter:selector];
}

+ (BOOL)selectorIsReserved:(SEL)selector
{
    NSString *selectorString = NSStringFromSelector(selector);
    return [reservedSelectorsAsStrings containsObject:selectorString];
}

+ (BOOL)selectorIsPropertySetter:(SEL)selector
{
    NSString *selectorString = NSStringFromSelector(selector);
    return [selectorString hasPrefix:@"set"] && [selectorString hasSuffix:@":"];
}

+ (void)provideDynamicImplementationToConstructDefinitionForSEL:(SEL)sel;
{
    IMP imp = &ImplementationToConstructDefinitionAndCatchArguments;
    class_addMethod(self, sel, imp, "@");
}

static id ImplementationToConstructDefinitionAndCatchArguments(TyphoonAssembly *me, SEL selector, ...) {
    va_list list;
    va_start(list, selector);
    TyphoonRuntimeArguments *args = [TyphoonRuntimeArguments argumentsFromVAList:list selector:selector];
    va_end(list);

    NSString *key = [TyphoonAssemblySelectorAdviser keyForAdvisedSEL:selector];
    return [me->_definitionBuilder builtDefinitionForKey:key args:args];
}

/* ====================================================================================================================================== */
#pragma mark - Initialization & Destruction

- (id)init
{
    self = [super init];
    if (self) {
        _definitionBuilder = [[TyphoonAssemblyDefinitionBuilder alloc] initWithAssembly:self];
        _adviser = [[TyphoonAssemblyAdviser alloc] initWithAssembly:self];
    }
    return self;
}

- (void)dealloc
{
    [TyphoonAssemblyAdviser undoAdviseMethods:self];
}

/* ====================================================================================================================================== */
#pragma mark - <TyphoonObjectWithCustomInjection>

- (id <TyphoonPropertyInjection, TyphoonParameterInjection>)typhoonCustomObjectInjection
{
    return [[TyphoonInjectionByComponentFactory alloc] init];
}

/* ====================================================================================================================================== */
#pragma mark - Interface Methods

- (void)resolveCollaboratingAssemblies
{
    TyphoonCollaboratingAssemblyPropertyEnumerator
        *enumerator = [[TyphoonCollaboratingAssemblyPropertyEnumerator alloc] initWithAssembly:self];

    for (NSString *propertyName in enumerator.collaboratingAssemblyProperties) {
        [self setCollaboratingAssemblyProxyOnPropertyNamed:propertyName];
    }
}

- (void)setCollaboratingAssemblyProxyOnPropertyNamed:(NSString *)name
{
    [self setValue:[TyphoonCollaboratingAssemblyProxy proxy] forKey:name];
}

- (TyphoonComponentFactory *)asFactory
{
    return (id)self;
}

/* ====================================================================================================================================== */
#pragma mark - Private Methods

- (NSArray *)definitions
{
    return [_definitionBuilder builtDefinitions];
}

- (TyphoonDefinition *)definitionForKey:(NSString *)key
{
    for (TyphoonDefinition *definition in [self definitions]) {
        if ([definition.key isEqualToString:key]) {
            return definition;
        }
    }
    return nil;
}

- (void)prepareForUse
{
    self.definitionSelectors = [self.adviser enumerateDefinitionSelectors];
    [self.adviser adviseAssembly];
}


@end