lib/
├── main.dart
├── firebase_options.dart
├── architecture.md
│
├── app/
│   ├── app.dart
│   ├── app_shell.dart
│   └── router.dart
│
├── core/
│   ├── constants/
│   │   ├── constants.dart
│   │   ├── app_accessibility.dart
│   │   ├── app_colors.dart
│   │   ├── app_icons.dart
│   │   ├── app_strings.dart
│   │   ├── app_limits.dart
│   │   └── feature_flags.dart
│   ├── theme/
│   │   ├── theme.dart
│   │   ├── app_theme.dart
│   │   ├── app_layout.dart
│   │   ├── app_shadows.dart
│   │   ├── app_spacing.dart
│   │   ├── app_text_styles.dart
│   │   └── premium_theme.dart
│   ├── extensions/
│   │   ├── string_extensions.dart
│   │   ├── datetime_extensions.dart
│   │   └── double_extensions.dart
│   ├── utils/
│   │   ├── date_utils.dart
│   │   ├── validation_utils.dart
│   │   ├── streak_calculator.dart
│   │   └── pdf_generator.dart
│   └── exceptions/
│       ├── app_exception.dart
│       ├── sync_exception.dart
│       └── validation_exception.dart
│
├── providers/
│   ├── auth_provider.dart
│   ├── session_provider.dart
│   ├── schedule_provider.dart
│   ├── streak_provider.dart
│   ├── subscription_provider.dart
│   ├── sync_provider.dart
│   └── analytics_provider.dart
│
├── features/
│   ├── auth/
│   │   ├── models/
│   │   ├── screens/
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   └── forgot_password_screen.dart
│   │   ├── widgets/
│   │   └── services/
│   ├── onboarding/
│   │   ├── models/
│   │   ├── screens/
│   │   │   ├── welcome_screen.dart
│   │   │   ├── pet_setup_screen.dart
│   │   │   └── schedule_setup_screen.dart
│   │   └── widgets/
│   ├── home/
│   │   ├── models/
│   │   ├── screens/
│   │   │   └── home_screen.dart
│   │   └── widgets/
│   │       ├── streak_display.dart
│   │       ├── next_session_card.dart
│   │       └── quick_actions.dart
│   ├── logging/
│   │   ├── models/
│   │   │   ├── fluid_session.dart
│   │   │   └── stress_level.dart
│   │   ├── screens/
│   │   │   ├── quick_log_screen.dart
│   │   │   ├── detailed_log_screen.dart
│   │   │   └── session_history_screen.dart
│   │   └── widgets/
│   │       ├── volume_input.dart
│   │       ├── stress_selector.dart
│   │       └── injection_site_picker.dart
│   ├── profile/
│   │   ├── models/
│   │   │   ├── cat_profile.dart
│   │   │   └── medical_info.dart
│   │   ├── screens/
│   │   │   ├── profile_screen.dart
│   │   │   └── medical_details_screen.dart
│   │   ├── widgets/
│   │   └── services/
│   ├── schedule/
│   │   ├── models/
│   │   │   ├── fluid_schedule.dart
│   │   │   └── reminder_settings.dart
│   │   ├── screens/
│   │   │   ├── schedule_screen.dart
│   │   │   └── reminder_settings_screen.dart
│   │   ├── widgets/
│   │   └── services/
│   ├── progress/
│   │   ├── models/
│   │   ├── screens/
│   │   │   ├── progress_screen.dart
│   │   │   └── detailed_analytics_screen.dart (premium)
│   │   └── widgets/
│   │       ├── adherence_chart.dart
│   │       └── stress_trends.dart
│   ├── resources/
│   │   ├── models/
│   │   ├── screens/
│   │   │   ├── resources_screen.dart
│   │   │   └── stress_free_guide_screen.dart
│   │   └── widgets/
│   ├── subscription/
│   │   ├── models/
│   │   │   ├── subscription_status.dart
│   │   │   └── feature_access.dart
│   │   ├── screens/
│   │   │   ├── subscription_screen.dart
│   │   │   └── payment_screen.dart
│   │   ├── widgets/
│   │   └── services/
│   ├── settings/
│   │   ├── models/
│   │   ├── screens/
│   │   │   ├── settings_screen.dart
│   │   │   └── privacy_screen.dart
│   │   └── widgets/
│   ├── exports/ (premium)
│   │   ├── models/
│   │   ├── screens/
│   │   │   └── export_screen.dart
│   │   ├── widgets/
│   │   └── services/
│   │       └── pdf_export_service.dart
│   ├── inventory/ (premium)
│   │   ├── models/
│   │   │   └── fluid_inventory.dart
│   │   ├── screens/
│   │   │   └── inventory_screen.dart
│   │   ├── widgets/
│   │   └── services/
│   └── insights/ (premium)
│       ├── models/
│       │   └── pattern_insight.dart
│       ├── screens/
│       │   └── insights_screen.dart
│       ├── widgets/
│       └── services/
│
├── shared/
│   ├── models/
│   │   ├── base_model.dart
│   │   ├── app_user.dart
│   │   ├── api_response.dart
│   │   └── sync_item.dart
│   ├── repositories/
│   │   ├── base_repository.dart
│   │   ├── session_repository.dart
│   │   ├── profile_repository.dart
│   │   ├── schedule_repository.dart
│   │   ├── user_repository.dart
│   │   └── analytics_repository.dart
│   ├── services/
│   │   ├── firebase_service.dart
│   │   ├── sync_service.dart
│   │   ├── notification_service.dart
│   │   ├── reminder_scheduler.dart
│   │   ├── analytics_service.dart
│   │   ├── privacy_service.dart
│   │   ├── validation_service.dart
│   │   └── backup_service.dart
│   └── widgets/
│       ├── accessibility/
│       │   ├── hydra_focus_indicator.dart
│       │   └── hydra_touch_target.dart
│       ├── buttons/
│       │   ├── hydra_button.dart
│       │   ├── hydra_fab.dart
│       │   └── premium_button.dart
│       ├── cards/
│       │   ├── hydra_card.dart
│       │   ├── premium_card.dart
│       │   └── medical_data_card.dart
│       ├── forms/
│       │   ├── validated_text_field.dart
│       │   ├── volume_slider.dart
│       │   └── time_picker.dart
│       ├── feedback/
│       │   ├── success_animation.dart
│       │   ├── streak_celebration.dart
│       │   └── offline_indicator.dart
│       ├── layout/
│       │   ├── screen_wrapper.dart
│       │   └── premium_wrapper.dart
│       └── navigation/
│           ├── hydra_navigation_bar.dart
│           └── pet_selector.dart
│
└── l10n/
    ├── app_localizations.dart
    ├── app_en.arb
    ├── app_fr.arb
    └── app_de.arb