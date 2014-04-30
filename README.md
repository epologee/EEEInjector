# EEEInjector

[![Build Status](https://travis-ci.org/epologee/EEEInjector.svg)](https://travis-ci.org/epologee/EEEInjector)
[![Version](http://cocoapod-badges.herokuapp.com/v/EEEInjector/badge.png)](http://cocoadocs.org/docsets/EEEInjector)
[![Platform](http://cocoapod-badges.herokuapp.com/p/EEEInjector/badge.png)](http://cocoadocs.org/docsets/EEEInjector)

f.k.a. [TwelveTwentyToolkit/TTTInjector](https://github.com/TwelveTwenty/TwelveTwentyToolkit-ObjC)

###Dependency Injection
If you've never heard of it, it can be a bit hard to immediately grasp the concept and the power of [Dependency Injection](http://en.wikipedia.org/wiki/Dependency_injection#Highly_coupled_dependency)(DI), but once you've worked with it, you will not want to go without again. DI is about much more than reducing the reliance on singletons, see the [benefits section on Wikipedia](http://en.wikipedia.org/wiki/Dependency_injection#Benefits). 

There are other existing frameworks that allow for dependency injection in Objective-C, with the [objection framework](https://github.com/atomicobject/objection) being the most prominent. Unfortunately, the syntactical sugar that objection adds to your code is somewhat 'weird', and because it's not instantly obvious what the meta-code does, it will confuse your colleagues and/or clients, and hardly get anyone excited about it.

Several features:

+ Runtime substitution of class instances by instances of a subclasses
+ Class or protocol based injection mapping
+ Automatic lazy injection of `@dynamic` properties
+ Comparmentalized singletons (per injector instance, great for TDD purposes)
+ Preset object injections, including named objects
+ Block based injections that run the moment you access them
+ Single-serving injections (unmap after use)

## Installation

EEEInjector is available through [CocoaPods](http://cocoapods.org), to install it simply run `pod install` after adding the following line to your `Podfile`:

    pod "EEEInjector"

## Usage

Have a look at the [Kiwi](https://github.com/allending/Kiwi) test [specs](InjectorTests/Specs) in the Xcode `Injector.xcworkspace` to see the features that the Injector currently supports.

## Author

Eric-Paul Lecluse, e@epologee.com

## License

This is free and unencumbered software released into the public domain. See the 
LICENSE file for more info.
