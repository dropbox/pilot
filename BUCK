#
#   Pilot
#
#   Note on the `configs` section of apple_libraries below: setting SKIP_INSTALL to NO for static
#   library configs would create a generic Xcode archive which can not be uploaded the App Store.
#   Learn more at: https://developer.apple.com/library/archive/technotes/tn2215/_index.html
#

skip_install_configs = {
    "SKIP_INSTALL": "YES",
}

library_configs = {
    'Debug': skip_install_configs,
    'Profile': skip_install_configs,
    'Release': skip_install_configs
}


apple_library(
    name = 'Pilot',
    swift_version = '4.2',
    srcs = [
        'Core/Source/Mutex.swift',
        'Core/Source/Async.swift',
        'Core/Source/Observable/ObservableType.swift',
        'Core/Source/Token.swift',
        'Core/Source/Downcast.swift',
        'Core/Source/Logging/Logger.swift',
        'Core/Source/Logging/FileLogger.swift',
        'Core/Source/Logging/ConsoleLogger.swift',
        'Core/Source/MVVM/View.swift',
        'Core/Source/MVVM/CompoundAction.swift',
        'Core/Source/MVVM/SectionedModelCollection.swift',
        'Core/Source/MVVM/Model.swift',
        'Core/Source/MVVM/FilteredModelCollection.swift',
        'Core/Source/MVVM/StaticModelCollection.swift',
        'Core/Source/MVVM/AsyncModelCollection.swift',
        'Core/Source/MVVM/ModelCollection.swift',
        'Core/Source/MVVM/NestedModelCollection.swift',
        'Core/Source/MVVM/ViewModelBinding.swift',
        'Core/Source/MVVM/ComposedModelCollection.swift',
        'Core/Source/MVVM/ViewModel.swift',
        'Core/Source/MVVM/ViewModelUserEvents.swift',
        'Core/Source/MVVM/SimpleModelCollection.swift',
        'Core/Source/MVVM/StaticModel.swift',
        'Core/Source/MVVM/SecondaryActionInfo.swift',
        'Core/Source/MVVM/Context.swift',
        'Core/Source/MVVM/EmptyModelCollection.swift',
        'Core/Source/MVVM/DiffEngine.swift',
        'Core/Source/MVVM/MappedModelCollection.swift',
        'Core/Source/MVVM/ViewLayout.swift',
        'Core/Source/MVVM/StaticViewBindingProvider.swift',
        'Core/Source/MVVM/SwitchableModelCollection.swift',
        'Core/Source/MVVM/Action.swift',
        'Core/Source/MVVM/ScoredModelCollection.swift',
        'Core/Source/MVVM/SortedModelCollection.swift',
    ],
    frameworks = [
        '$SDKROOT/System/Library/Frameworks/Foundation.framework',
    ],
    modular = True,
    tests = [':PilotTests']  if read_config('custom', 'skip_tests') == 'false' else [ ],
    info_plist = "Core/Source/iOS-Info.plist",
    info_plist_substitutions = {
        'PRODUCT_BUNDLE_IDENTIFIER': 'com.dropbox.Pilot',
        'CURRENT_PROJECT_VERSION': '1'
    },
    configs = library_configs,
    visibility = ['PUBLIC'],
)

apple_test(
    name = 'PilotTests',
    swift_version = '4.2',
    info_plist = 'Core/Tests/Info.plist',
    info_plist_substitutions = {
        'PRODUCT_BUNDLE_IDENTIFIER': 'com.dropbox.PilotTests'
    },
    srcs = glob(['Core/Tests/**/*.swift']),
    deps = [':Pilot'],
    frameworks = [
        '$SDKROOT/System/Library/Frameworks/Foundation.framework',
        '$PLATFORM_DIR/Developer/Library/Frameworks/XCTest.framework',
    ],
)

#
#   PilotUI
#

pilotui_shared_srcs = [
    "UI/Source/Layout/LayoutConstraints.swift",
    "UI/Source/Extensions/Collection.swift",
    "UI/Source/Extensions/AssociatedObjects.swift",
    "UI/Source/Alerts/AlertAction.swift",
    "UI/Source/PlatformAliases.swift",
    "UI/Source/CollectionViews/CollectionViewModelDataSource.swift",
    "UI/Source/CollectionViews/CollectionViewInternals.swift",
    "UI/Source/CollectionViews/CollectionHostedView.swift",    
]

apple_library(
    name = 'PilotUI-iOS',
    module_name = 'PilotUI',
    header_path_prefix = 'PilotUI',
    swift_version = '4.2',
    srcs =  pilotui_shared_srcs + 
            [
                "UI/Source/Alerts/ios/UIAlertController+AlertAction.swift",
                "UI/Source/CollectionViews/ios/CollectionViewHostCell.swift",
                "UI/Source/CollectionViews/ios/CollectionViewHostReusableView.swift",
                "UI/Source/CollectionViews/ios/CollectionViewController.swift",
            ],
    deps = [':Pilot'],
    frameworks = [
        '$SDKROOT/System/Library/Frameworks/Foundation.framework',
        '$SDKROOT/System/Library/Frameworks/UIKit.framework'
    ],
    modular = True,
    info_plist = 'UI/Source/Info-iOS.plist',
    info_plist_substitutions = {
        'PRODUCT_BUNDLE_IDENTIFIER': 'com.dropbox.PilotUI',
        'CURRENT_PROJECT_VERSION': '1'
    },
    configs = library_configs,
    visibility = ['PUBLIC'],
)

apple_library(
    name = 'PilotUI-macOS',
    module_name = 'PilotUI',
    swift_version = '4.2',
    srcs = pilotui_shared_srcs + 
            [
                "UI/Source/Common/mac/ModelCollectionViewController.swift",
                "UI/Source/Common/mac/ModelCollectionStateViewTypes.swift",
                "UI/Source/OutlineViews/mac/OutlineViewModelDataSource.swift",
                "UI/Source/OutlineViews/mac/NestedModelCollectionTreeController.swift",
                "UI/Source/OutlineViews/mac/OutlineViewController.swift",
                "UI/Source/CollectionViews/mac/CollectionView.swift",
                "UI/Source/CollectionViews/mac/CollectionViewHostItem.swift",
                "UI/Source/CollectionViews/mac/CollectionViewHostReusableView.swift",
                "UI/Source/CollectionViews/mac/CollectionViewController.swift",
                "UI/Source/AppKitExtensions/NSMenu+Action.swift",
                "UI/Source/AppKitExtensions/NSEvent+Keys.swift",
                "UI/Source/AppKitExtensions/NSCollectionView+Selection.swift",
                "UI/Source/AppKitExtensions/NestableScrollView.swift",
            ],
    deps = [':Pilot'],
    tests = [':PilotUITests-macOS'] if read_config('custom', 'skip_tests') == 'false' else [ ],
    modular = True,
    frameworks = [
        '$SDKROOT/System/Library/Frameworks/Foundation.framework',
        '$SDKROOT/System/Library/Frameworks/AppKit.framework',
        '$SDKROOT/System/Library/Frameworks/CoreServices.framework'
    ],
    info_plist = 'UI/Source/Info-macOS.plist',
    info_plist_substitutions = {
        'PRODUCT_BUNDLE_IDENTIFIER': 'com.dropbox.PilotUI',
        'CURRENT_PROJECT_VERSION': '1'
    },
    configs = library_configs,
    visibility = ['PUBLIC'],
)

apple_test(
    swift_version = '4.2',
    name = 'PilotUITests-macOS',
    info_plist = 'UI/Tests/Info-macOS.plist',
    info_plist_substitutions = {
        'PRODUCT_BUNDLE_IDENTIFIER': 'com.dropbox.PilotUITests',
    },
    srcs = glob(["UI/Source/OutlineViews/mac/NestedModelCollectionTreeControllerTests.swift",
                "UI/Tests/**/mac/*.swift"]),
    deps = [':Pilot', ':PilotUI-macOS'],
    frameworks = [
        '$SDKROOT/System/Library/Frameworks/Foundation.framework',
        '$PLATFORM_DIR/Developer/Library/Frameworks/XCTest.framework',
    ],
)

#
#   Examples
#

#
#   CatalogCore
# 

apple_library(
    name = 'CatalogCore',
    swift_version = '4.2',
    srcs = glob([
        'Examples/Catalog/Core/**/*.swift',
    ], exclude = [
        '**/Tests/*',
        '**/UITests/*'
    ]),
    deps = [
        ':Pilot',
    ],
    configs = library_configs,
    frameworks = [
        '$SDKROOT/System/Library/Frameworks/Foundation.framework'
    ],
)

#
#   Catalog-iOS
#
apple_asset_catalog(
    name = 'Catalog-iOS.assets',
    dirs = ['Examples/Catalog/iOS/Resources/Assets.xcassets'],
    app_icon = 'AppIcon',
)

apple_resource(
    name = 'Catalog-iOS.resources',
    variants = glob(['Examples/Catalog/iOS/Resources/Base.lproj/*'])
)

catalog_ios_settings = {
    'DEVELOPMENT_LANGUAGE': 'en',
    'PRODUCT_BUNDLE_IDENTIFIER': 'com.dropbox.pilot.catalog-ios'
}

catalog_ios_configs = {
    'Debug': catalog_ios_settings,
    'Profile': catalog_ios_settings,
    'Release': catalog_ios_settings
}

apple_binary(
    name = 'Catalog-iOS.binary',
    module_name = "CatalogIOS",
    swift_version = '4.2',
    srcs = glob([
        'Examples/Catalog/iOS/**/*.swift'
    ], exclude = [
        '**/Tests/*',
        '**/UITests/*'
    ]),
    deps = [
        ':Catalog-iOS.assets',
        ':CatalogCore',
        ':Pilot',
        ':PilotUI-iOS'
    ],
    frameworks = [
        '$SDKROOT/System/Library/Frameworks/Foundation.framework',
        '$SDKROOT/System/Library/Frameworks/UIKit.framework'
    ],
    configs = catalog_ios_configs
)

apple_bundle(
    name = 'Catalog-iOS',
    extension = 'app',
    binary = ':Catalog-iOS.binary',
    deps = [':Catalog-iOS.resources'],
    info_plist = 'Examples/Catalog/Info-iOS.plist',
    info_plist_substitutions = catalog_ios_settings
)

apple_package(
  name = 'Catalog-iOS.ipa',
  bundle = ':Catalog-iOS',
)

#
#   Catalog-macOS
#

catalog_macos_settings = {
    'DEVELOPMENT_LANGUAGE': 'en',
    'PRODUCT_BUNDLE_IDENTIFIER': 'com.dropbox.pilot.catalog-macOS',
    'MACOSX_DEPLOYMENT_TARGET': '10.12'
}

catalog_macos_configs = {
    'Debug': catalog_macos_settings,
    'Profile': catalog_macos_settings,
    'Release': catalog_macos_settings
}

apple_asset_catalog(
    name = 'Catalog-macOS.assets',
    dirs = ['Examples/Catalog/macOS/Resources/Assets.xcassets'],
    app_icon = 'AppIcon',
)

apple_resource(
    name = 'Catalog-macOS.resources',
    files = ['Examples/Catalog/macOS/Resources/Catalog.xib']
)

apple_binary(
    name = 'Catalog-macOS.binary',
    module_name = 'Catalog',
    swift_version = '4.2',
    srcs = glob([
        'Examples/Catalog/Core/**/*.swift',
        'Examples/Catalog/macOS/**/*.swift'
    ], exclude = [
        '**/Tests/*',
        '**/UITests/*'
    ]),
    entitlements_file = 'Examples/Catalog/Catalog-macOS.entitlements',
    deps = [
        ':CatalogCore',
        ':Pilot',
        ':PilotUI-macOS',
        ':Catalog-macOS.resources',
    ],
    frameworks = [
        '$SDKROOT/System/Library/Frameworks/Foundation.framework',
        '$SDKROOT/System/Library/Frameworks/AppKit.framework'
    ],
    configs = catalog_macos_configs
)

apple_bundle(
    name = 'Catalog-macOS',
    extension = 'app',
    binary = ':Catalog-macOS.binary',
    deps = [':PilotUI-macOS', ':Pilot'],
    info_plist = 'Examples/Catalog/Info-macOS.plist',
    info_plist_substitutions = catalog_macos_settings
)

#
#  DirectoryViewer
#

directoryviewer_macos_settings = {
    'DEVELOPMENT_LANGUAGE': 'en',
    'PRODUCT_BUNDLE_IDENTIFIER': 'com.dropbox.pilot.directoryviewer',
    'MACOSX_DEPLOYMENT_TARGET': '10.12'
}

directoryviewer_macos_configs = {
    'Debug': directoryviewer_macos_settings,
    'Profile': directoryviewer_macos_settings,
    'Release': directoryviewer_macos_settings
}

apple_asset_catalog(
    name = 'DirectoryViewer-macOS.assets',
    dirs = ['Examples/DirectoryViewer/DirectoryViewer/Assets.xcassets'],
    app_icon = 'AppIcon',
)

apple_resource(
    name = 'DirectoryViewer-macOS.resources',
    variants = glob(['Examples/DirectoryViewer/DirectoryViewer/Base.lproj/*'])
)

apple_binary(
    name = 'DirectoryViewer-macOS.binary',
    module_name = 'DirectoryViewer',
    swift_version = '4.2',
    srcs = glob([
        'Examples/DirectoryViewer/**/*.swift',
    ]),
    entitlements_file = 'Examples/DirectoryViewer/DirectoryViewer/DirectoryViewer.entitlements',
    deps = [
        ':Pilot',
        ':PilotUI-macOS',
        ':DirectoryViewer-macOS.resources',
    ],
    frameworks = [
        '$SDKROOT/System/Library/Frameworks/Foundation.framework',
        '$SDKROOT/System/Library/Frameworks/AppKit.framework'
    ],
    configs = directoryviewer_macos_configs
)

apple_bundle(
    name = 'DirectoryViewer-macOS',
    extension = 'app',
    binary = ':DirectoryViewer-macOS.binary',
    deps = [':PilotUI-macOS', ':Pilot'],
    info_plist = 'Examples/DirectoryViewer/DirectoryViewer/Info.plist',
    info_plist_substitutions = directoryviewer_macos_settings
)

#
#   iTunesSearch
#

apple_asset_catalog(
    name = 'iTunesSearch.assets',
    dirs = ['Examples/iTunesSearch/Shared/Assets.xcassets'],
    app_icon = 'AppIcon',
)

#
#   iTunesSearch-iOS
#

apple_resource(
    name = 'iTunesSearch-iOS.resources',
    variants = glob(['Examples/iTunesSearch/iOS/Base.lproj/*'])
)

itunessearch_ios_settings = {
    'DEVELOPMENT_LANGUAGE': 'en',
    'PRODUCT_BUNDLE_IDENTIFIER': 'com.dropbox.pilot.itunessearch-ios'
}

itunessearch_ios_configs = {
    'Debug': itunessearch_ios_settings,
    'Profile': itunessearch_ios_settings,
    'Release': itunessearch_ios_settings
}

apple_binary(
    name = 'iTunesSearch-iOS.binary',
    module_name = "iTunesSearch",
    swift_version = '4.2',
    srcs = glob([
        'Examples/iTunesSearch/iOS/*.swift',
        'Examples/iTunesSearch/Shared/*.swift'
    ]),
    deps = [
        ':iTunesSearch.assets',
        ':Pilot',
        ':PilotUI-iOS'
    ],
    frameworks = [
        '$SDKROOT/System/Library/Frameworks/Foundation.framework',
        '$SDKROOT/System/Library/Frameworks/UIKit.framework'
    ],
    configs = itunessearch_ios_configs
)

apple_bundle(
    name = 'iTunesSearch-iOS',
    extension = 'app',
    binary = ':iTunesSearch-iOS.binary',
    deps = [':iTunesSearch-iOS.resources'],
    info_plist = 'Examples/iTunesSearch/iOS/Info.plist',
    info_plist_substitutions = itunessearch_ios_settings
)

apple_package(
  name = 'iTunesSearch-iOS.ipa',
  bundle = ':iTunesSearch-iOS',
)

#
#   iTunesSearch-macOS
#

itunessearch_macos_settings = {
    'DEVELOPMENT_LANGUAGE': 'en',
    'PRODUCT_BUNDLE_IDENTIFIER': 'com.dropbox.pilot.itunessearch-macos',
    'MACOSX_DEPLOYMENT_TARGET': '10.12'
}

itunessearch_macos_configs = {
    'Debug': itunessearch_macos_settings,
    'Profile': itunessearch_macos_settings,
    'Release': itunessearch_macos_settings
}

apple_resource(
    name = 'iTunesSearch-macOS.resources',
    variants = glob(['Examples/iTunesSearch/macOS/Base.lproj/*'])
)

apple_binary(
    name = 'iTunesSearch-macOS.binary',
    module_name = 'iTunesSearch',
    swift_version = '4.2',
    srcs = glob([
        'Examples/iTunesSearch/macOS/*.swift',
        'Examples/iTunesSearch/Shared/*.swift'
    ]),
    deps = [
        ':Pilot',
        ':PilotUI-macOS',
        ':iTunesSearch-macOS.resources',
        ':iTunesSearch.assets'
    ],
    frameworks = [
        '$SDKROOT/System/Library/Frameworks/Foundation.framework',
        '$SDKROOT/System/Library/Frameworks/AppKit.framework'
    ],
    configs = itunessearch_macos_configs
)

apple_bundle(
    name = 'iTunesSearch-macOS',
    extension = 'app',
    binary = ':iTunesSearch-macOS.binary',
    info_plist = 'Examples/iTunesSearch/macOS/Info.plist',
    info_plist_substitutions = itunessearch_macos_settings
)
