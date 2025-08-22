lib
├── app
│   ├── app.dart
│   ├── app_shell.dart
│   └── router.dart
│
├── core
│   ├── constants
│   │   ├── constants.dart
│   │   ├── app_accessibility.dart
│   │   ├── app_colors.dart
│   │   ├── app_icons.dart
│   │   ├── app_strings.dart
│   │   ├── app_limits.dart
│   │   └── feature_flags.dart
│   │
│   ├── theme
│   │   ├── theme.dart
│   │   ├── app_theme.dart
│   │   ├── app_layout.dart
│   │   ├── app_shadows.dart
│   │   ├── app_spacing.dart
│   │   ├── app_text_styles.dart
│   │   └── premium_theme.dart
│   │
│   ├── extensions
│   │   ├── string_extensions.dart
│   │   ├── datetime_extensions.dart
│   │   └── double_extensions.dart
│   │
│   ├── utils
│   │   ├── date_utils.dart
│   │   ├── validation_utils.dart
│   │   ├── streak_calculator.dart
│   │   └── pdf_generator.dart
│   │
│   └── exceptions
│       ├── app_exception.dart
│       ├── sync_exception.dart
│       └── validation_exception.dart
│
├── providers
│   ├── auth_provider.dart
│   ├── session_provider.dart
│   ├── schedule_provider.dart
│   ├── streak_provider.dart
│   ├── subscription_provider.dart
│   ├── sync_provider.dart
│   └── analytics_provider.dart
│
├── features
│   ├── auth
│   │   ├── screens
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   └── forgot_password_screen.dart
│   │   ├── models
│   │   ├── providers
│   │   ├── widgets
│   │   └── services
│   │
│   ├── onboarding
│   │   ├── screens
│   │   │   ├── welcome_screen.dart
│   │   │   ├── pet_setup_screen.dart
│   │   │   └── schedule_setup_screen.dart
│   │   ├── models
│   │   └── widgets
│   │
│   ├── home
│   │   ├── screens
│   │   │   └── home_screen.dart
│   │   ├── widgets
│   │   │   ├── streak_display.dart
│   │   │   ├── next_session_card.dart
│   │   │   └── quick_actions.dart
│   │   └── models
│   │
│   ├── logging
│   │   ├── screens
│   │   │   ├── quick_log_screen.dart
│   │   │   ├── detailed_log_screen.dart
│   │   │   └── session_history_screen.dart
│   │   ├── widgets
│   │   │   ├── volume_input.dart
│   │   │   ├── stress_selector.dart
│   │   │   └── injection_site_picker.dart
│   │   └── models
│   │       ├── fluid_session.dart
│   │       └── stress_level.dart
│   │
│   ├── profile
│   │   ├── screens
│   │   │   ├── profile_screen.dart
│   │   │   └── medical_details_screen.dart
│   │   ├── models
│   │   │   ├── cat_profile.dart
│   │   │   └── medical_info.dart
│   │   ├── widgets
│   │   └── services
│   │
│   ├── schedule
│   │   ├── screens
│   │   │   ├── schedule_screen.dart
│   │   │   └── reminder_settings_screen.dart
│   │   ├── models
│   │   │   ├── fluid_schedule.dart
│   │   │   └── reminder_settings.dart
│   │   ├── widgets
│   │   └── services
│   │
│   ├── progress
│   │   ├── screens
│   │   │   ├── progress_screen.dart
│   │   │   └── detailed_analytics_screen.dart (*premium*)
│   │   ├── widgets
│   │   │   ├── adherence_chart.dart
│   │   │   └── stress_trends.dart
│   │   └── models
│   │
│   ├── resources
│   │   ├── screens
│   │   │   ├── resources_screen.dart
│   │   │   └── stress_free_guide_screen.dart
│   │   ├── models
│   │   └── widgets
│   │
│   ├── subscription
│   │   ├── screens
│   │   │   ├── subscription_screen.dart
│   │   │   └── payment_screen.dart
│   │   ├── models
│   │   │   ├── subscription_status.dart
│   │   │   └── feature_access.dart
│   │   ├── widgets
│   │   └── services
│   │
│   ├── settings
│   │   ├── screens
│   │   │   ├── settings_screen.dart
│   │   │   └── privacy_screen.dart
│   │   ├── models
│   │   └── widgets
│   │
│   ├── exports (*premium*)
│   │   ├── screens
│   │   │   └── export_screen.dart
│   │   ├── services
│   │   │   └── pdf_export_service.dart
│   │   ├── models
│   │   └── widgets
│   │
│   ├── inventory (*premium*)
│   │   ├── screens
│   │   │   └── inventory_screen.dart
│   │   ├── models
│   │   │   └── fluid_inventory.dart
│   │   ├── widgets
│   │   └── services
│   │
│   └── insights (*premium*)
│       ├── screens
│       │   └── insights_screen.dart
│       ├── models
│       │   └── pattern_insight.dart
│       ├── widgets
│       └── services
│
├── shared
│   ├── models
│   │   ├── base_model.dart
│   │   ├── app_user.dart
│   │   ├── api_response.dart
│   │   └── sync_item.dart
│   │
│   ├── repositories
│   │   ├── base_repository.dart
│   │   ├── session_repository.dart
│   │   ├── profile_repository.dart
│   │   ├── schedule_repository.dart
│   │   ├── user_repository.dart
│   │   └── analytics_repository.dart
│   │
│   ├── services
│   │   ├── firebase_service.dart
│   │   ├── sync_service.dart
│   │   ├── notification_service.dart
│   │   ├── reminder_scheduler.dart
│   │   ├── analytics_service.dart
│   │   ├── privacy_service.dart
│   │   ├── validation_service.dart
│   │   └── backup_service.dart
│   │
│   └── widgets
│       ├── accessibility
│       │   ├── hydra_focus_indicator.dart
│       │   └── hydra_touch_target.dart
│       ├── buttons
│       │   ├── hydra_button.dart
│       │   ├── hydra_fab.dart
│       │   └── premium_button.dart
│       ├── cards
│       │   ├── hydra_card.dart
│       │   ├── premium_card.dart
│       │   └── medical_data_card.dart
│       ├── forms
│       │   ├── validated_text_field.dart
│       │   ├── volume_slider.dart
│       │   └── time_picker.dart
│       ├── feedback
│       │   ├── success_animation.dart
│       │   ├── streak_celebration.dart
│       │   └── offline_indicator.dart
│       ├── layout
│       │   ├── screen_wrapper.dart
│       │   └── premium_wrapper.dart
│       └── navigation
│           ├── hydra_navigation_bar.dart
│           └── pet_selector.dart
│
└── l10n
    ├── app_localizations.dart
    ├── app_en.arb
    ├── app_fr.arb
    └── app_de.arb
