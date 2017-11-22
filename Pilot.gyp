{
  'variables': {
    'pilot_core_sources': [
      'Core/Source/Observable/Observable.swift',
      'Core/Source/Async.swift',
      'Core/Source/Downcast.swift',
      'Core/Source/Logging/ConsoleLogger.swift',
      'Core/Source/Logging/FileLogger.swift',
      'Core/Source/Logging/Logger.swift',
      'Core/Source/MVVM/Action.swift',
      'Core/Source/MVVM/AsyncModelCollection.swift',
      'Core/Source/MVVM/CompoundAction.swift',
      'Core/Source/MVVM/Context.swift',
      'Core/Source/MVVM/DiffEngine.swift',
      'Core/Source/MVVM/EmptyModelCollection.swift',
      'Core/Source/MVVM/FilteredModelCollection.swift',
      'Core/Source/MVVM/MappedModelCollection.swift',
      'Core/Source/MVVM/Model.swift',
      'Core/Source/MVVM/ModelCollection.swift',
      'Core/Source/MVVM/MultiplexModelCollection.swift',
      'Core/Source/MVVM/ScoredModelCollection.swift',
      'Core/Source/MVVM/SecondaryActionInfo.swift',
      'Core/Source/MVVM/SimpleModelCollection.swift',
      'Core/Source/MVVM/SortedModelCollection.swift',
      'Core/Source/MVVM/StaticModel.swift',
      'Core/Source/MVVM/StaticModelCollection.swift',
      'Core/Source/MVVM/StaticViewBindingProvider.swift',
      'Core/Source/MVVM/SwitchableModelCollection.swift',
      'Core/Source/MVVM/View.swift',
      'Core/Source/MVVM/ViewLayout.swift',
      'Core/Source/MVVM/ViewModel.swift',
      'Core/Source/MVVM/ViewModelBinding.swift',
      'Core/Source/MVVM/ViewModelUserEvents.swift',
      'Core/Source/Observable/Observable.swift',
      'Core/Source/Observable/ObservableData.swift',
      'Core/Source/Token.swift',
      'Core/Source/Hash/SpookyV2.cpp',
      'Core/Source/Hash/Hash.cpp',
    ],
    'pilot_ui_ios_sources': [
      'UI/Source/Alerts/AlertAction.swift',
      'UI/Source/Alerts/UIAlertController+AlertAction.swift',

      'UI/Source/CollectionViews/CollectionHostedView.swift',
      'UI/Source/CollectionViews/CollectionViewInternals.swift',
      'UI/Source/CollectionViews/CollectionViewModelDataSource.swift',

      'UI/Source/CollectionViews/ios/CollectionViewController.swift',
      'UI/Source/CollectionViews/ios/CollectionViewHostCell.swift',
      'UI/Source/CollectionViews/ios/CollectionViewHostReusableView.swift',
      'UI/Source/CollectionViews/ios/Nested/NestedModelCollectionView.swift',

      'UI/Source/Extensions/AssociatedObjects.swift',
      'UI/Source/Extensions/Collection.swift',
      'UI/Source/Layout/LayoutConstraints.swift',
      'UI/Source/PlatformAliases.swift',
    ],
    'pilot_ui_mac_sources': [
      'UI/Source/AppKitExtensions/NSCollectionView+Selection.swift',
      'UI/Source/AppKitExtensions/NSEvent+Keys.swift',
      'UI/Source/AppKitExtensions/NSMenu+Action.swift',

      'UI/Source/CollectionViews/CollectionHostedView.swift',
      'UI/Source/CollectionViews/CollectionViewInternals.swift',
      'UI/Source/CollectionViews/CollectionViewModelDataSource.swift',

      'UI/Source/CollectionViews/mac/CollectionView.swift',
      'UI/Source/CollectionViews/mac/CollectionViewController.swift',
      'UI/Source/CollectionViews/mac/CollectionViewHostItem.swift',
      'UI/Source/CollectionViews/mac/CollectionViewHostReusableView.swift',

      'UI/Source/Extensions/AssociatedObjects.swift',
      'UI/Source/Extensions/Collection.swift',
      'UI/Source/Layout/LayoutConstraints.swift',
      'UI/Source/PlatformAliases.swift',
    ],
  },

  'conditions': [
    ['OS=="ios"',
      {
        'targets': [
          {
            'target_name': 'Pilot',
            'mac_bundle': 1,
            'hard_dependency': 1,
            'type': 'static_library',
            'mac_framework_headers': [
              'Core/Source/Pilot.h',
              'Core/Source/Hash/Hash.h',
            ],
            'mac_framework_private_headers': [
              'Core/Source/Hash/SpookyV2.h',
            ],
            'sources': [
                '<@(pilot_core_sources)',
            ],
            'xcode_settings': {
              'SWIFT_VERSION': '3.2',
              'INFOPLIST_FILE': 'Core/Source/iOS-Info.plist',
            },
            'xcode_config_file': 'Configuration/Pilot-Target.xcconfig',
            'link_settings': {
              'libraries': [ '$(SDKROOT)/System/Library/Frameworks/Foundation.framework' ],
            },
          },
          {
            'target_name': 'PilotUI',
            'mac_bundle': 1,
            'hard_dependency': 1,
            'type': 'static_library',
            'mac_framework_headers': [
              'UI/Source/PilotUI.h',
            ],
            'sources': [
                '<@(pilot_ui_ios_sources)',
            ],
            'dependencies': [
              'Pilot',
            ],
            'xcode_settings': {
              'SWIFT_VERSION': '3.2',
              'INFOPLIST_FILE': 'UI/Source/Info-iOS.plist',
            },
            'xcode_config_file': 'Configuration/Pilot-Target.xcconfig',
            'link_settings': {
              'libraries': [
                '$(SDKROOT)/System/Library/Frameworks/Foundation.framework',
                '$(SDKROOT)/System/Library/Frameworks/UIKit.framework',
              ],
            },
          },
       ],
      },
    ],
    ['OS=="mac"',
      {
        'targets': [
          {
            'target_name': 'Pilot',
            'mac_bundle': 1,
            'hard_dependency': 1,
            'type': 'static_library',
            'mac_framework_headers': [
              'Core/Source/Pilot.h',
              'Core/Source/Hash/Hash.h',
            ],
            'mac_framework_private_headers': [
              'Core/Source/Hash/SpookyV2.h',
            ],
            'sources': [
                '<@(pilot_core_sources)',
            ],
            'xcode_settings': {
              'SWIFT_VERSION': '3.2',
              'INFOPLIST_FILE': 'Core/Source/Mac-Info.plist',
            },
            'xcode_config_file': 'Configuration/Pilot-Target.xcconfig',
          },
          {
            'target_name': 'PilotUI',
            'mac_bundle': 1,
            'hard_dependency': 1,
            'type': 'static_library',
            'mac_framework_headers': [
              'UI/Source/PilotUI.h',
            ],
            'sources': [
                '<@(pilot_ui_ios_sources)',
            ],
            'dependencies': [
              'Pilot',
            ],
            'xcode_settings': {
              'SWIFT_VERSION': '3.2',
              'INFOPLIST_FILE': 'UI/Source/Info-macOS.plist',
            },
            'xcode_config_file': 'Configuration/Pilot-Target.xcconfig',
            'link_settings': {
              'libraries': [
                '$(SDKROOT)/System/Library/Frameworks/AppKit.framework',
                '$(SDKROOT)/System/Library/Frameworks/Foundation.framework',
              ],
            },
          },
        ],
      },
    ],
  ],

  'configurations': {
      'Debug': {
        'xcode_config_file': 'Configuration/Pilot-Project-Debug.xcconfig',
      },
      'Release': {
        'xcode_config_file': 'Configuration/Pilot-Project-Release.xcconfig',
      },
  },
}
