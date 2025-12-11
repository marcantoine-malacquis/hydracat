lib/
├── main.dart                        # Default entry point
├── main_development.dart            # Development flavor entry
├── main_production.dart             # Production flavor entry
├── firebase_options.dart            # Firebase configuration
│
├── app/                             # App-level configuration
│   ├── README.md                    # App layer documentation
│   ├── app.dart                     # Main app widget
│   ├── app_shell.dart               # App shell structure
│   ├── tab_page_registry.dart       # Registry for tab pages used by navigation shell
│   └── router.dart                  # Navigation routing
│
├── core/                            # Infrastructure layer
│   ├── config/                      # App configuration
│   │   └── flavor_config.dart       # Build flavor settings
│   ├── constants/                   # App-wide constants
│   │   ├── constants.dart           # General constants
│   │   ├── app_accessibility.dart   # Accessibility standards
│   │   ├── app_animations.dart      # Animation constants
│   │   ├── app_colors.dart          # Color palette
│   │   ├── app_icons.dart           # Icon definitions
│   │   ├── app_strings.dart         # String constants
│   │   ├── lab_reference_ranges.dart # Lab reference range constants
│   │   ├── symptom_colors.dart      # Symptom color palette
│   │   ├── app_limits.dart          # App limitations
│   │   └── feature_flags.dart       # Feature toggles
│   ├── icons/                       # Icon registry and loading
│   │   ├── icon_provider.dart       # Provides icon assets
│   │   └── icons.dart               # Icon definitions export
│   ├── theme/                       # UI theming
│   │   ├── README.md                # Theme documentation
│   │   ├── theme.dart               # Theme exports
│   │   ├── app_theme.dart           # Main theme config
│   │   ├── app_layout.dart          # Layout constants
│   │   ├── app_shadows.dart         # Shadow definitions
│   │   ├── app_spacing.dart         # Spacing system
│   │   ├── app_text_styles.dart     # Typography
│   │   ├── app_border_radius.dart   # Border radius tokens
│   │   ├── card_constants.dart      # Card theming constants
│   │   └── premium_theme.dart       # Premium styling
│   ├── extensions/                  # Dart extensions
│   │   ├── build_context_extensions.dart # Context utilities
│   │   ├── string_extensions.dart   # String utilities
│   │   ├── datetime_extensions.dart # Date utilities
│   │   └── double_extensions.dart   # Number utilities
│   ├── utils/                       # Helper utilities
│   │   ├── chart_tooltip_positioning.dart # Chart tooltip layout helpers
│   │   ├── chart_utils.dart         # General chart utilities
│   │   ├── date_utils.dart          # Date manipulation
│   │   ├── dosage_text_utils.dart   # Dosage text formatting
│   │   ├── dosage_utils.dart        # Dosage calculations
│   │   ├── medication_unit_utils.dart # Medication unit conversions
│   │   ├── number_input_utils.dart  # Number input handling
│   │   ├── snackbar_layout_utils.dart # Snackbar layout helpers
│   │   ├── symptom_descriptor_utils.dart # Symptom descriptor helpers
│   │   ├── validation_utils.dart    # Input validation
│   │   ├── streak_calculator.dart   # Streak logic
│   │   ├── weight_utils.dart        # Weight conversions & formatting
│   │   └── pdf_generator.dart       # PDF creation
│   ├── validation/                  # Validation infrastructure
│   │   └── models/                  # Validation data models
│   │       └── validation_result.dart # Validation result & error models
│   └── exceptions/                  # Error handling
│       ├── app_exception.dart       # Base exception
│       ├── sync_exception.dart      # Sync errors
│       └── validation_exception.dart # Validation errors
│
├── providers/                       # Riverpod state providers
│   ├── profile/                     # Profile-specific providers
│   │   ├── profile_cache_manager.dart # Profile cache management
│   │   └── schedule_notification_handler.dart # Schedule notification handling
│   ├── calendar_help_provider.dart # Calendar help state
│   ├── analytics_provider.dart      # Usage analytics
│   ├── auth_provider.dart           # Authentication state
│   ├── cache_management_provider.dart # Cache management state
│   ├── inventory_provider.dart      # Inventory state
│   ├── connectivity_provider.dart   # Connectivity state
│   ├── dashboard_provider.dart      # Dashboard state
│   ├── logging_provider.dart        # Logging state
│   ├── logging_queue_provider.dart  # Logging queue state
│   ├── onboarding_provider.dart     # Onboarding state
│   ├── profile_provider.dart        # Profile state
│   ├── progress_edit_provider.dart  # Progress edit state
│   ├── progress_provider.dart       # Progress state
│   ├── schedule_history_provider.dart # Schedule history state
│   ├── symptoms_chart_provider.dart # Symptoms chart data
│   ├── sync_provider.dart           # Data synchronization
│   ├── theme_provider.dart          # Theme state
│   ├── weight_provider.dart         # Weight tracking state
│   ├── weight_unit_provider.dart    # Weight unit preference
│   ├── session_provider.dart        # Fluid session state
│   ├── schedule_provider.dart       # Schedule management
│   ├── streak_provider.dart         # Streak tracking
│   ├── subscription_provider.dart   # Premium features
│   └── weekly_progress_provider.dart # Weekly progress state
│
├── features/                        # Feature modules
│   ├── auth/                        # User authentication
│   │   ├── models/                  # Auth data models
│   │   │   ├── app_user.dart        # User model
│   │   │   └── auth_state.dart      # Auth state model
│   │   ├── screens/                 # Auth UI screens
│   │   │   ├── login_screen.dart    # Login interface
│   │   │   ├── register_screen.dart # Registration form
│   │   │   ├── email_verification_screen.dart # Email verification
│   │   │   └── forgot_password_screen.dart # Password reset
│   │   ├── widgets/                 # Auth UI components
│   │   │   ├── social_signin_buttons.dart # Social auth buttons
│   │   │   └── lockout_dialog.dart  # Account lockout dialog
│   │   ├── mixins/                  # Auth utility mixins
│   │   │   ├── auth_error_handler_mixin.dart # Error handling
│   │   │   └── auth_loading_state_mixin.dart # Loading states
│   │   ├── exceptions/              # Auth-specific exceptions
│   │   │   └── auth_exceptions.dart # Authentication errors
│   │   └── services/                # Auth business logic
│   │       └── auth_service.dart    # Authentication service
│   ├── health/                      # Health tracking
│   │   ├── models/                  # Health data models
│   │   │   ├── health_parameter.dart # Health parameter definition
│   │   │   ├── symptom_bucket.dart  # Grouped symptom data bucket
│   │   │   ├── symptom_entry.dart   # Symptom entry record
│   │   │   ├── symptom_granularity.dart # Symptom time granularity
│   │   │   ├── symptom_raw_value.dart # Raw symptom input value
│   │   │   ├── symptom_type.dart    # Symptom type enum
│   │   │   ├── weight_data_point.dart # Weight data point
│   │   │   └── weight_granularity.dart # Time granularity for weight data
│   │   ├── screens/                 # Health UI screens
│   │   │   ├── symptoms_screen.dart # Symptom tracking screen
│   │   │   └── weight_screen.dart   # Weight tracking screen
│   │   ├── widgets/                 # Health UI components
│   │   │   ├── symptom_enum_input.dart # Enum-based symptom input
│   │   │   ├── symptom_number_input.dart # Numeric symptom input
│   │   │   ├── symptom_slider.dart  # Symptom severity slider
│   │   │   ├── symptoms_entry_dialog.dart # Symptom entry dialog
│   │   │   ├── symptoms_stacked_bar_chart.dart # Symptom stacked bar chart
│   │   │   ├── weight_entry_dialog.dart # Weight entry dialog
│   │   │   ├── weight_line_chart.dart # Weight visualization chart
│   │   │   └── weight_stat_card.dart # Weight statistics card
│   │   ├── services/                # Health business logic
│   │   │   ├── symptom_severity_converter.dart # Convert symptom severities
│   │   │   ├── symptoms_service.dart # Symptom tracking service
│   │   │   ├── weight_cache_service.dart # Weight data caching
│   │   │   └── weight_service.dart  # Weight tracking service
│   │   └── exceptions/              # Health-specific exceptions
│   │       └── health_exceptions.dart # Health tracking errors
│   ├── onboarding/                  # User onboarding
│   │   ├── models/                  # Onboarding data
│   │   │   ├── onboarding_data.dart # Onboarding data model
│   │   │   ├── onboarding_progress.dart # Progress tracking
│   │   │   ├── onboarding_step.dart # Step enumeration
│   │   │   └── treatment_data.dart  # Treatment setup data
│   │   ├── screens/                 # Onboarding flows
│   │   │   ├── add_medication_screen.dart # Medication setup
│   │   │   ├── ckd_medical_info_screen.dart # CKD medical info
│   │   │   ├── onboarding_completion_screen.dart # Completion screen
│   │   │   ├── pet_basics_screen.dart # Pet basic info
│   │   │   ├── welcome_screen.dart  # Welcome intro
│   │   │   ├── pet_setup_screen.dart # Pet configuration
│   │   │   └── schedule_setup_screen.dart # Initial schedule
│   │   ├── widgets/                 # Onboarding components
│   │   │   ├── gender_selector.dart # Gender selection widget
│   │   │   ├── iris_stage_selector.dart # IRIS stage selector
│   │   │   ├── lab_values_input.dart # Lab values input
│   │   │   ├── medication_overlay_wrapper.dart # Medication overlay
│   │   │   ├── medication_summary_card.dart # Medication summary
│   │   │   ├── onboarding_progress_indicator.dart # Progress indicator
│   │   │   ├── onboarding_screen_wrapper.dart # Screen wrapper
│   │   │   ├── rotating_wheel_picker.dart # Wheel picker widget
│   │   │   ├── time_picker_group.dart # Time picker group
│   │   │   ├── treatment_popup_wrapper.dart # Treatment popup
│   │   │   └── weight_unit_selector.dart # Weight unit selector
│   │   ├── services/                # Onboarding business logic
│   │   │   ├── onboarding_service.dart # Onboarding flow service
│   │   │   └── onboarding_validation_service.dart # Onboarding validation
│   │   ├── exceptions/              # Onboarding-specific exceptions
│   │   │   └── onboarding_exceptions.dart # Onboarding errors
│   │   └── debug_onboarding_replay.dart # Debug helper to replay onboarding
│   ├── home/                        # Main dashboard
│   │   ├── models/                  # Home data models
│   │   │   ├── dashboard_state.dart # Dashboard state management
│   │   │   ├── pending_fluid_treatment.dart # Pending fluid treatment data
│   │   │   └── pending_treatment.dart # Pending treatment data
│   │   ├── screens/                 # Home UI screens
│   │   │   ├── home_screen.dart     # Main dashboard
│   │   │   └── component_demo_screen.dart # UI showcase
│   │   └── widgets/                 # Home components
│   │       ├── home_hero_header.dart # Dashboard hero header
│   │       ├── dashboard_empty_state.dart # Empty state UI
│   │       ├── dashboard_success_popup.dart # Success feedback
│   │       ├── pending_fluid_card.dart # Fluid treatment card
│   │       ├── pending_fluid_card_skeleton.dart # Loading skeleton
│   │       ├── pending_treatment_card.dart # Treatment card
│   │       ├── pending_treatment_card_skeleton.dart # Loading skeleton
│   │       ├── treatment_confirmation_popup.dart # Treatment confirmation
│   │       ├── widgets.dart         # Widget exports
│   │       ├── streak_display.dart  # Streak counter
│   │       ├── next_session_card.dart # Next session info
│   │       └── quick_actions.dart   # Quick action buttons
│   ├── learn/                       # Educational content
│   │   ├── models/                  # Learn data models
│   │   ├── screens/                 # Learn UI screens
│   │   │   ├── learn_screen.dart    # Learn landing screen
│   │   │   └── discover_screen.dart    # Main discover screen
│   │   └── widgets/                 # Learn components
│   ├── logging/                     # Session logging
│   │   ├── models/                  # Logging data models
│   │   │   ├── daily_summary_cache.dart # Daily summary caching
│   │   │   ├── dashboard_logging_context.dart # Dashboard logging context
│   │   │   ├── fluid_session.dart   # Fluid session data
│   │   │   ├── logging_mode.dart    # Logging mode enum
│   │   │   ├── logging_operation.dart # Logging operation state
│   │   │   ├── logging_state.dart   # Logging state management
│   │   │   ├── medication_session.dart # Medication session data
│   │   │   ├── stress_level.dart    # Stress level enum
│   │   │   └── treatment_choice.dart # Treatment choice enum
│   │   ├── screens/                 # Logging interfaces
│   │   │   ├── fluid_logging_screen.dart # Fluid logging screen
│   │   │   ├── medication_logging_screen.dart # Medication logging screen
│   │   │   ├── logging_screen.dart  # Main logging screen
│   │   │   ├── quick_log_screen.dart # Quick logging
│   │   │   ├── detailed_log_screen.dart # Detailed entry
│   │   │   └── session_history_screen.dart # History view
│   │   ├── widgets/                 # Logging components
│   │   │   ├── logging_bottom_sheet_helper.dart # Bottom sheet helper
│   │   │   ├── injection_site_selector.dart # Injection site selector
│   │   │   ├── logging_popup_wrapper.dart # Logging popup container
│   │   │   ├── medication_dosage_input.dart # Medication dosage input
│   │   │   ├── medication_selection_card.dart # Medication selection card
│   │   │   ├── quick_log_success_popup.dart # Quick log success feedback
│   │   │   ├── session_update_dialog.dart # Session update dialog
│   │   │   ├── stress_level_selector.dart # Stress level selector
│   │   │   ├── success_indicator.dart # Success indicator widget
│   │   │   ├── treatment_choice_popup.dart # Treatment choice popup
│   │   │   ├── weight_calculator_dialog.dart # Weight calculator dialog
│   │   │   ├── weight_calculator_form.dart # Weight calculator form
│   │   │   ├── volume_input.dart    # Volume selector
│   │   │   ├── stress_selector.dart # Stress level picker
│   │   │   └── injection_site_picker.dart # Site selector
│   │   ├── services/                # Logging business logic
│   │   │   ├── README.md            # Logging services documentation
│   │   │   ├── logging_service.dart # Core logging service
│   │   │   ├── logging_validation_service.dart # Logging validation
│   │   │   ├── offline_logging_service.dart # Offline logging queue
│   │   │   ├── overlay_service.dart # Overlay management
│   │   │   ├── session_read_service.dart # Session reading service
│   │   │   ├── summary_cache_service.dart # Summary caching
│   │   │   ├── summary_service.dart # Summary calculations
│   │   │   ├── monthly_array_helper.dart # Monthly array calculation helper
│   │   │   └── weight_calculator_service.dart # Weight calculator service
│   │   └── exceptions/              # Logging-specific exceptions
│   │       ├── logging_error_handler.dart # Error handler
│   │       └── logging_exceptions.dart # Logging errors
│   ├── notifications/               # Notifications & reminders
│   │   ├── models/                  # Notification data models
│   │   │   ├── device_token.dart    # FCM device token
│   │   │   ├── notification_settings.dart # Notification preferences
│   │   │   └── scheduled_notification_entry.dart # Scheduled notification data
│   │   ├── providers/               # Notification providers
│   │   │   ├── notification_coordinator.dart # Coordinates notification flows
│   │   │   └── notification_provider.dart # Notification state provider
│   │   ├── screens/                 # Notification screens
│   │   ├── widgets/                 # Notification components
│   │   │   ├── notification_status_widget.dart # Status indicator
│   │   │   ├── permission_preprompt.dart # Permission pre-prompt
│   │   │   └── privacy_details_bottom_sheet.dart # Privacy info sheet
│   │   ├── services/                # Notification services
│   │   │   ├── device_token_service.dart # Device token management
│   │   │   ├── notification_cleanup_service.dart # Notification cleanup
│   │   │   ├── notification_error_handler.dart # Error handling
│   │   │   ├── notification_index_store.dart # Notification indexing
│   │   │   ├── notification_settings_service.dart # Settings management
│   │   │   ├── notification_tap_handler.dart # Tap handling
│   │   │   ├── permission_prompt_service.dart # Permission prompts
│   │   │   ├── reminder_plugin.dart # Local notification plugin
│   │   │   └── reminder_service.dart # Reminder scheduling
│   │   ├── utils/                   # Notification utilities
│   │   │   ├── notification_id.dart # ID generation
│   │   │   ├── scheduling_helpers.dart # Scheduling utilities
│   │   │   ├── time_slot_formatter.dart # Time formatting
│   │   │   └── time_validation.dart # Time validation
│   │   └── notifications_explanations.md # Notification concepts documentation
│   ├── profile/                     # Pet profile management
│   │   ├── models/                  # Profile data models
│   │   │   ├── cat_profile.dart     # Pet profile data
│   │   │   ├── lab_measurement.dart # Lab measurement data
│   │   │   ├── lab_result.dart      # Lab result model
│   │   │   ├── latest_lab_summary.dart # Latest lab summary snapshot
│   │   │   ├── medical_info.dart    # Medical information
│   │   │   ├── schedule.dart        # Schedule model
│   │   │   ├── schedule_dto.dart    # Schedule data transfer object
│   │   │   └── schedule_history_entry.dart # Schedule history entry
│   │   ├── screens/                 # Profile interfaces
│   │   │   ├── ckd_profile_screen.dart # CKD profile screen
│   │   │   ├── create_fluid_schedule_screen.dart # Create fluid schedule
│   │   │   ├── fluid_schedule_screen.dart # Fluid schedule screen
│   │   │   ├── medication_schedule_screen.dart # Medication schedule
│   │   │   ├── profile_screen.dart  # Profile overview
│   │   │   └── medical_details_screen.dart # Medical details
│   │   ├── widgets/                 # Profile components
│   │   │   ├── ckd_stage_hero_card.dart # CKD stage hero UI
│   │   │   ├── debug_panel.dart     # Debug information panel
│   │   │   ├── editable_medical_field.dart # Editable medical field
│   │   │   ├── profile_navigation_tile.dart # Navigation tile
│   │   │   ├── lab_history_card.dart # Lab history card
│   │   │   ├── lab_history_section.dart # Lab history section
│   │   │   ├── lab_result_detail_popup.dart # Lab result detail popup
│   │   │   ├── lab_value_display_with_gauge.dart # Lab value display with gauge
│   │   │   ├── lab_values_entry_dialog.dart # Lab values entry dialog
│   │   │   └── pet_info_card.dart   # Pet info summary card
│   │   ├── services/                # Profile business logic
│   │   │   ├── pet_service.dart     # Pet profile service
│   │   │   ├── profile_validation_service.dart # Profile validation
│   │   │   ├── schedule_coordinator.dart # Schedule coordination
│   │   │   ├── schedule_history_service.dart # Schedule history management
│   │   │   └── schedule_service.dart # Schedule management service
│   │   └── exceptions/              # Profile-specific exceptions
│   │       └── profile_exceptions.dart # Profile errors
│   ├── schedule/                    # Treatment scheduling
│   │   ├── models/                  # Schedule data models
│   │   │   ├── fluid_schedule.dart  # Treatment schedule
│   │   │   └── reminder_settings.dart # Notification settings
│   │   ├── screens/                 # Schedule interfaces
│   │   │   ├── schedule_screen.dart # Schedule overview
│   │   │   └── reminder_settings_screen.dart # Reminder config
│   │   ├── widgets/                 # Schedule components
│   │   └── services/                # Schedule services
│   ├── progress/                    # Treatment progress
│   │   ├── models/                  # Progress data models
│   │   │   ├── fluid_chart_data.dart # Fluid chart data model
│   │   │   ├── fluid_month_chart_data.dart # Monthly fluid chart data
│   │   │   ├── day_dot_status.dart  # Day status for calendar
│   │   │   ├── treatment_day_bucket.dart # Treatment day aggregation
│   │   │   └── injection_site_stats.dart # Injection site statistics
│   │   ├── providers/               # Progress providers
│   │   │   ├── fluid_chart_provider.dart # Provides fluid chart data
│   │   │   └── injection_sites_provider.dart # Injection sites data provider
│   │   ├── screens/                 # Progress interfaces
│   │   │   ├── progress_screen.dart # Progress overview
│   │   │   ├── injection_sites_analytics_screen.dart # Injection sites analytics
│   │   │   └── detailed_analytics_screen.dart # Analytics (premium)
│   │   ├── widgets/                 # Progress components
│   │   │   ├── fluid_volume_bar_chart.dart # Fluid volume bar chart
│   │   │   ├── fluid_volume_month_chart.dart # Monthly fluid volume chart
│   │   │   ├── adherence_chart.dart # Adherence visualization
│   │   │   ├── calendar_help_popup.dart # Calendar help dialog
│   │   │   ├── fluid_edit_dialog.dart # Fluid editing dialog
│   │   │   ├── injection_sites_donut_chart.dart # Injection sites chart
│   │   │   ├── insights_card.dart   # Reusable analytics card
│   │   │   ├── medication_edit_dialog.dart # Medication editing dialog
│   │   │   ├── progress_day_detail_popup.dart # Day detail popup
│   │   │   ├── progress_week_calendar.dart # Weekly calendar widget
│   │   │   ├── stress_trends.dart   # Stress trend charts
│   │   │   └── water_drop_progress_card.dart # Weekly fluid progress card
│   │   ├── services/                # Progress business logic
│   │   │   └── week_status_calculator.dart # Week status calculation
│   │   └── utils/                   # Progress utilities
│   │       └── memoization.dart     # Memoization helpers
│   ├── resources/                   # Educational content
│   │   ├── models/                  # Resource data models
│   │   ├── screens/                 # Resource interfaces
│   │   │   ├── resources_screen.dart # Resource library
│   │   │   └── stress_free_guide_screen.dart # Stress guide
│   │   └── widgets/                 # Resource components
│   ├── subscription/                # Premium features
│   │   ├── models/                  # Subscription models
│   │   │   ├── subscription_status.dart # Subscription state
│   │   │   └── feature_access.dart  # Feature permissions
│   │   ├── screens/                 # Subscription interfaces
│   │   │   ├── subscription_screen.dart # Premium overview
│   │   │   └── payment_screen.dart  # Payment processing
│   │   ├── widgets/                 # Subscription components
│   │   └── services/                # Payment services
│   ├── settings/                    # App settings
│   │   ├── models/                  # Settings models
│   │   ├── screens/                 # Settings interfaces
│   │   │   ├── notification_settings_screen.dart # Notification settings
│   │   │   ├── settings_screen.dart # Settings overview
│   │   │   └── privacy_screen.dart  # Privacy settings
│   │   └── widgets/                 # Settings components
│   │       └── weight_unit_selector.dart # Weight unit selector
│   ├── exports/ (premium)           # Data export features
│   │   ├── models/                  # Export data models
│   │   ├── screens/                 # Export interfaces
│   │   │   └── export_screen.dart   # Export configuration
│   │   ├── widgets/                 # Export components
│   │   └── services/                # Export services
│   │       └── pdf_export_service.dart # PDF generation
│   ├── inventory/ (premium)         # Supply tracking
│   │   ├── models/                  # Inventory models
│   │   │   ├── inventory_calculations.dart # Inventory math helpers
│   │   │   ├── inventory_state.dart # Inventory state model
│   │   │   ├── refill_entry.dart    # Refill entry record
│   │   │   └── fluid_inventory.dart # Supply tracking data
│   │   ├── screens/                 # Inventory interfaces
│   │   │   └── inventory_screen.dart # Inventory management
│   │   ├── widgets/                 # Inventory components
│   │   │   └── refill_popup.dart    # Refill action popup
│   │   └── services/                # Inventory services
│   │       └── inventory_service.dart # Inventory management service
│   └── insights/ (premium)          # Advanced analytics
│       ├── models/                  # Insight models
│       │   └── pattern_insight.dart # Pattern analysis
│       ├── screens/                 # Insight interfaces
│       │   └── insights_screen.dart # Analytics dashboard
│       ├── widgets/                 # Insight components
│       └── services/                # Analytics services
│
├── shared/                          # Shared components
│   ├── models/                      # Common data models
│   │   ├── base_model.dart          # Base model class
│   │   ├── app_user.dart            # Global user model
│   │   ├── api_response.dart        # API response wrapper
│   │   ├── daily_summary.dart       # Daily summary data
│   │   ├── fluid_daily_summary_view.dart # Fluid daily summary view
│   │   ├── medication_daily_summary_view.dart # Medication daily summary view
│   │   ├── login_attempt_data.dart  # Login attempt tracking
│   │   ├── monthly_summary.dart     # Monthly summary data
│   │   ├── symptoms_daily_summary_view.dart # Symptoms daily summary view
│   │   ├── summary_update_dto.dart  # Summary update DTO
│   │   ├── sync_item.dart           # Sync data model
│   │   ├── treatment_summary_base.dart # Treatment summary base
│   │   └── weekly_summary.dart      # Weekly summary data
│   ├── navigation/                  # Shared navigation helpers
│   │   └── tab_page_descriptor.dart # Descriptor for tab pages
│   ├── repositories/                # Data access layer
│   │   ├── base_repository.dart     # Base repository
│   │   ├── session_repository.dart  # Session data access
│   │   ├── profile_repository.dart  # Profile data access
│   │   ├── schedule_repository.dart # Schedule data access
│   │   ├── user_repository.dart     # User data access
│   │   └── analytics_repository.dart # Analytics data
│   ├── utils/                       # Shared utilities (placeholder for common helpers)
│   ├── services/                    # Core services
│   │   ├── cache_management_service.dart # Cache management
│   │   ├── connectivity_service.dart # Network connectivity
│   │   ├── fcm_background_handler.dart # FCM background handler
│   │   ├── feature_gate_service.dart # Feature gating
│   │   ├── firebase_service.dart    # Firebase integration
│   │   ├── login_attempt_service.dart # Login attempt management
│   │   ├── secure_preferences_service.dart # Secure storage
│   │   ├── theme_service.dart       # Theme management
│   │   ├── weight_unit_service.dart # Weight unit management
│   │   ├── sync_service.dart        # Data synchronization
│   │   ├── notification_service.dart # Push notifications
│   │   ├── reminder_scheduler.dart  # Reminder scheduling
│   │   ├── analytics_service.dart   # Usage analytics
│   │   ├── privacy_service.dart     # Privacy management
│   │   ├── validation_service.dart  # Data validation
│   │   └── backup_service.dart      # Data backup
│   └── widgets/                     # Reusable UI components
│       ├── accessibility/           # Accessibility components
│       │   ├── README.md            # Accessibility docs
│       │   ├── accessibility.dart   # A11y exports
│       │   ├── hydra_focus_indicator.dart # Focus indicator
│       │   ├── hydra_touch_target.dart # Touch target helper
│       │   └── touch_target_icon_button.dart # Touch target icon button
│       ├── bottom_sheets/           # Bottom sheet components
│       │   ├── bottom_sheets.dart   # Bottom sheet exports
│       │   └── hydra_bottom_sheet.dart # Standardized bottom sheet
│       ├── buttons/                 # Button components
│       │   ├── buttons.dart         # Button exports
│       │   ├── hydra_button.dart    # Primary button
│       │   ├── hydra_fab.dart       # Floating action button
│       │   └── premium_button.dart  # Premium CTA button
│       ├── cards/                   # Card components
│       │   ├── cards.dart           # Card exports
│       │   ├── hydra_card.dart      # Base card component
│       │   ├── premium_card.dart    # Premium feature card
│       │   ├── medical_data_card.dart # Medical info card
│       │   └── navigation_card.dart # Navigation card component
│       ├── dialogs/                 # Dialog components
│       │   ├── dialogs.dart         # Dialog exports
│       │   ├── hydra_alert_dialog.dart # Alert dialog
│       │   ├── hydra_dialog.dart    # Base dialog component
│       │   ├── no_schedules_dialog.dart # No schedules dialog
│       │   └── unsaved_changes_dialog.dart # Unsaved changes dialog
│       ├── empty_states/            # Empty state components
│       │   └── onboarding_cta_empty_state.dart # Onboarding CTA empty state
│       ├── fluid/                   # Fluid-specific components
│       │   ├── fluid_daily_summary_card.dart # Fluid daily summary card
│       │   ├── water_drop_painter.dart # Water drop painter
│       │   └── water_drop_progress_card.dart # Water drop progress card
│       ├── icons/                   # Icon components
│       │   ├── hydra_icon.dart      # Custom icon widget
│       │   ├── icon_container.dart  # Icon container widget
│       │   └── icons.dart           # Icon exports
│       ├── inputs/                  # Input components
│       │   ├── hydra_dropdown.dart  # Dropdown input
│       │   ├── hydra_slider.dart    # Slider input
│       │   ├── hydra_sliding_segmented_control.dart # Sliding segmented control
│       │   ├── hydra_switch.dart    # Switch input
│       │   ├── hydra_text_field.dart # Text field
│       │   ├── hydra_text_form_field.dart # Text form field
│       │   └── volume_input_adjuster.dart # Volume adjuster
│       ├── forms/                   # Form components
│       │   ├── validated_text_field.dart # Input field
│       │   ├── volume_slider.dart   # Volume selection
│       │   └── time_picker.dart     # Time selection
│       ├── feedback/                # Feedback components
│       │   ├── feedback.dart        # Feedback exports
│       │   ├── success_animation.dart # Success animation
│       │   ├── streak_celebration.dart # Streak milestone
│       │   ├── offline_indicator.dart # Offline status
│       │   ├── hydra_progress_indicator.dart # Progress indicator
│       │   ├── hydra_refresh_indicator.dart # Pull-to-refresh indicator
│       │   ├── hydra_snack_bar.dart # Snackbar component
│       │   └── validation_error_display.dart # Validation error UI
│       ├── loading/                 # Loading components
│       │   ├── loading.dart         # Loading exports
│       │   └── loading_overlay.dart # Loading overlay
│       ├── medication/              # Medication shared components
│       │   └── medication_daily_summary_card.dart # Medication summary card
│       ├── status/                  # Status components
│       │   └── connection_status_widget.dart # Connection status
│       ├── layout/                  # Layout components
│       │   ├── dev_banner.dart      # Development banner
│       │   ├── app_scaffold.dart    # App scaffold wrapper
│       │   ├── layout.dart          # Layout exports
│       │   ├── layout_wrapper.dart  # Main layout wrapper
│       │   ├── screen_wrapper.dart  # Screen container
│       │   ├── section_wrapper.dart # Content sections
│       │   └── premium_wrapper.dart # Premium feature wrapper
│       ├── navigation/              # Navigation components
│       │   ├── app_page_transitions.dart # Page transitions
│       │   ├── hydra_app_bar.dart   # App bar widget
│       │   ├── hydra_navigation_bar.dart # Bottom navigation
│       │   ├── navigation.dart      # Navigation exports
│       │   ├── slide_transition_page.dart # Slide transition page
│       │   └── pet_selector.dart    # Pet selection
│       ├── pickers/                 # Picker components
│       │   ├── hydra_date_picker.dart # Date picker
│       │   └── hydra_time_picker.dart # Time picker
│       ├── symptoms/                # Symptom shared components
│       │   └── symptoms_daily_summary_card.dart # Symptoms summary card
│       ├── custom_dropdown.dart     # Custom dropdown widget
│       ├── selection_card.dart      # Selection card widget
│       ├── validation_error_display.dart # Validation error display
│       ├── hydra_back_button.dart   # Back button widget
│       ├── hydra_gauge.dart         # Gauge widget
│       ├── TurnPlatformSpecific.md  # Platform adaptation notes
│       ├── verification_gate.dart   # Feature verification gate
│       └── widgets.dart             # Widget exports
│
└── l10n/                            # Internationalization
    ├── app_localizations.dart       # Generated localizations
    ├── app_localizations_en.dart    # English localizations (generated)
    ├── app_en.arb                   # English translations
    ├── app_fr.arb                   # French translations
    └── app_de.arb                   # German translations



## Update prompt

Please update @ideal_archi.md to reflect the current project structure. This file represents my ideal future architecture and gets updated regularly during development.

Instructions:
1. Add any new files and folders that exist in the current codebase but are not in the ideal_archi.md
2. Keep ALL existing entries in the file, even if they don't exist yet (these are planned features)
3. Ask me before deleting anything from the tree
4. Maintain the same format and structure with comments explaining each component

The file should represent both current implementation and future planned features.