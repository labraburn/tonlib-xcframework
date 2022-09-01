//
//  Created by Anton Spivak.
//

import Foundation

private let _openssl_platforms =
"""
## -*- mode: perl; -*-

my %targets = ();

%targets = (

    #—————————————————————————————————————————————————————————————————————
    # Base setting templates
    #—————————————————————————————————————————————————————————————————————
    
    "all-base" => {
        template         => 1,
        cflags           => '-isysroot $(CROSS_TOP)/SDKs/$(CROSS_SDK) -fno-common'
    },


    #—————————————————————————————————————————————————————————————————————
    # Base compiler target settings
    # - HAVE_FORK=0 for some targets lacking fork() in their SDK's.
    #—————————————————————————————————————————————————————————————————————

    "ios-base" => {
        inherit_from    => [ "all-base" ],
        template         => 1,
        cflags           => add('-mios-version-min=$(MIN_SDK_VERSION) -fembed-bitcode'),
    },

    "tvos-base" => {
        inherit_from     => [ "all-base" ],
        template         => 1,
        cflags           => add('-mtvos-version-min=$(MIN_SDK_VERSION) -fembed-bitcode'),
        defines          => [ "HAVE_FORK=0" ],
    },

    "watchos-base" => {
        inherit_from     => [ "all-base" ],
        template         => 1,
        cflags           => add('-mwatchos-version-min=$(MIN_SDK_VERSION) -fembed-bitcode'),
        defines          => [ "HAVE_FORK=0" ],
    },

    "macos-base" => {
        inherit_from     => [ "all-base" ],
        template         => 1,
        cflags           => add('-mmacosx-version-min=$(MIN_SDK_VERSION)  -fembed-bitcode'),
    },


    #—————————————————————————————————————————————————————————————————————
    # watchOS
    #—————————————————————————————————————————————————————————————————————

    # i386
    # Note that watchOS is still fundamentally a 32-bit operating
    # system (arm64_32 uses 32-bit address space), so i386 simulator architecture is appropriate.
    "watchos-simulator-i386" => {
        inherit_from     => [ "darwin-common", "watchos-base"],
        cflags           => add("-arch i386 -fembed-bitcode"),
        sys_id           => "WatchOS",
    },

    # armv7k (Apple Watch up to Series 3)
    "watchos-armv7k" => {
        inherit_from     => [ "darwin-common",  "watchos-base" ],
        cflags           => add("-arch armv7k -fembed-bitcode -fno-asm"),
        sys_id           => "WatchOS",
    },

    # arm64_32 (Apple Watch Series 4 onward)
    "watchos-arm64_32" => {
        inherit_from     => [ "darwin-common", "watchos-base"],
        cflags           => add("-arch arm64_32 -fembed-bitcode"),
        sys_id           => "WatchOS",
    },


    #—————————————————————————————————————————————————————————————————————
    # iOS
    #—————————————————————————————————————————————————————————————————————

    # x86_64 (simulator)
    "ios-simulator-x86_64" => {
        inherit_from     => [ "darwin64-x86_64-cc", "ios-base" ],
        sys_id           => "iOS",
    },

    # arm64 (simulator)
    "ios-simulator-arm64" => {
        inherit_from     => [ "darwin64-arm64-cc", "ios-base" ],
        cflags           => add("-target arm64-apple-ios13.0-simulator"),
        sys_id           => "iOS",
    },
    
    # arm64
    "ios-arm64" => {
        inherit_from     => [ "darwin-common", "ios-base", asm("aarch64_asm") ],
        cflags           => add("-arch arm64"),
        bn_ops           => "SIXTY_FOUR_BIT_LONG RC4_CHAR",
        perlasm_scheme   => "ios64",
        sys_id           => "iOS",
    },
       
            
    #—————————————————————————————————————————————————————————————————————
    # iOS (macCatalyst)
    # Because it's an iOS target, we will respect the iOS bitcode setting that is inherited
    #—————————————————————————————————————————————————————————————————————

    # x86_64
    "mac-catalyst-x86_64" => {
        inherit_from     => [ "darwin64-x86_64-cc", "ios-base" ],
        cflags           => add('-target x86_64-apple-ios$(MIN_SDK_VERSION)-macabi'),
        sys_id           => "MacOSX",
    },

    # arm64
    "mac-catalyst-arm64" => {
        inherit_from     => [ "darwin64-arm64-cc", "ios-base" ],
        cflags           => add('-target arm64-apple-ios$(MIN_SDK_VERSION)-macabi'),
        sys_id           => "MacOSX",
    },


    #—————————————————————————————————————————————————————————————————————
    # tvOS
    #—————————————————————————————————————————————————————————————————————

    ## x86_64
    "tvos-simulator-x86_64" => {
        inherit_from     => [ "darwin64-x86_64-cc", "tvos-base" ],
        cflags           => add("-fembed-bitcode"),
        sys_id           => "tvOS",
    },

    ## arm64
    "tvos-arm64" => {
        inherit_from     => [ "darwin-common", "tvos-base", asm("aarch64_asm") ],
        cflags           => add("-arch arm64"),
        bn_ops           => "SIXTY_FOUR_BIT_LONG RC4_CHAR",
        perlasm_scheme   => "ios64",
        sys_id           => "tvOS",
    },

    #—————————————————————————————————————————————————————————————————————
    # macOS
    #—————————————————————————————————————————————————————————————————————

    ## x86_64
    "macos-x86_64" => {
        inherit_from     => [ "darwin64-x86_64-cc", "macos-base" ],
        sys_id           => "macOS",
    },
    
    ## arm64
    "macos-arm64" => {
        inherit_from     => [ "darwin64-arm64-cc", "macos-base" ],
        sys_id           => "macOS",
    },
);
""".data(using: .utf8)!

extension Resource {
    
    static let openSSLPlatforms = Resource(contents: _openssl_platforms, fileName: "platforms.conf")
}
