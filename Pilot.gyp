{
  'variables': {
    'pilot_core_sources': [
       '<!@(find Core/Source -regex ".*\.swift")',
       '<!@(find Core/Source -regex ".*\.cpp")',
    ],
    'pilot_ui_ios_sources': [
       'UI/Source/PlatformAliases.swift',
       '<!@(find UI/Source/Extensions -regex ".*\.swift")',
       '<!@(find UI/Source/Layout -regex ".*\.swift")',
       '<!@(find UI/Source/CollectionViews -regex ".*\.swift")',
       '<!@(find UI/Source/Alerts -regex ".*\.swift")',
    ],
    'pilot_ui_mac_sources': [
       'UI/Source/PlatformAliases.swift',
       '<!@(find UI/Source/Extensions -regex ".*\.swift")',
       '<!@(find UI/Source/Layout -regex ".*\.swift")',
       '<!@(find UI/Source/CollectionViews -regex ".*\.swift")',
       '<!@(find UI/Source/AppKitExtensions -regex ".*\.swift")',
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
              '<@(pilot_ui_mac_sources)',
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
