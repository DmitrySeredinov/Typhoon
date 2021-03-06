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


#import <SenTestingKit/SenTestingKit.h>
#import "TyphoonCollaboratingAssemblyPropertyEnumerator.h"
#import "CollaboratingMiddleAgesAssembly.h"
#import "ExtendedMiddleAgesAssembly.h"
#import "ExtendedSimpleAssembly.h"
#import "TyphoonCollaboratingAssemblyPropertyEnumeratorTests_AssemblyWithProperty.h"

@interface TyphoonCollaboratingAssemblyPropertyEnumeratorTests : SenTestCase
@end


@implementation TyphoonCollaboratingAssemblyPropertyEnumeratorTests
{

}

- (void)test_assembly_property_implements_protocol
{
    TyphoonCollaboratingAssemblyPropertyEnumerator
        *enumerator = [[TyphoonCollaboratingAssemblyPropertyEnumerator alloc] initWithAssembly:[CollaboratingMiddleAgesAssembly assembly]];
    assertThat([enumerator collaboratingAssemblyProperties], onlyContains(@"quests", nil));
}

- (void)test_assembly_properties_include_superclasses
{
    TyphoonCollaboratingAssemblyPropertyEnumerator
        *enumerator = [[TyphoonCollaboratingAssemblyPropertyEnumerator alloc] initWithAssembly:[ExtendedSimpleAssembly assembly]];
    assertThat([enumerator collaboratingAssemblyProperties], containsInAnyOrder(@"assemblyA", @"assemblyB", nil));
}

- (void)test_excludes_non_assembly_types
{
    TyphoonCollaboratingAssemblyPropertyEnumerator
        *enumerator = [[TyphoonCollaboratingAssemblyPropertyEnumerator alloc] initWithAssembly:[AssemblyWithProperty assembly]];
    assertThat([enumerator collaboratingAssemblyProperties], onlyContains(@"assembly", nil));
}

@end