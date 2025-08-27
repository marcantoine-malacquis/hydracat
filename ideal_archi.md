lib/
├── main.dart                        # Default entry point
├── main_development.dart            # Development flavor entry
├── main_production.dart             # Production flavor entry
├── firebase_options.dart            # Firebase configuration
│
├── app/                             # App-level configuration
│   ├── app.dart                     # Main app widget
│   ├── app_shell.dart               # App shell structure
│   └── router.dart                  # Navigation routing
│
├── core/                            # Infrastructure layer
│   ├── config/                      # App configuration
│   │   └── flavor_config.dart       # Build flavor settings
│   ├── constants/                   # App-wide constants
│   │   ├── constants.dart           # General constants
│   │   ├── app_accessibility.dart   # Accessibility standards
│   │   ├── app_colors.dart          # Color palette
│   │   ├── app_icons.dart           # Icon definitions
│   │   ├── app_strings.dart         # String constants
│   │   ├── app_limits.dart          # App limitations
│   │   └── feature_flags.dart       # Feature toggles
│   ├── theme/                       # UI theming
│   │   ├── README.md                # Theme documentation
│   │   ├── theme.dart               # Theme exports
│   │   ├── app_theme.dart           # Main theme config
│   │   ├── app_layout.dart          # Layout constants
│   │   ├── app_shadows.dart         # Shadow definitions
│   │   ├── app_spacing.dart         # Spacing system
│   │   ├── app_text_styles.dart     # Typography
│   │   └── premium_theme.dart       # Premium styling
│   ├── extensions/                  # Dart extensions
│   │   ├── string_extensions.dart   # String utilities
│   │   ├── datetime_extensions.dart # Date utilities
│   │   └── double_extensions.dart   # Number utilities
│   ├── utils/                       # Helper utilities
│   │   ├── date_utils.dart          # Date manipulation
│   │   ├── validation_utils.dart    # Input validation
│   │   ├── streak_calculator.dart   # Streak logic
│   │   └── pdf_generator.dart       # PDF creation
│   └── exceptions/                  # Error handling
│       ├── app_exception.dart       # Base exception
│       ├── sync_exception.dart      # Sync errors
│       └── validation_exception.dart # Validation errors
│
├── providers/                       # Riverpod state providers
│   ├── auth_provider.dart           # Authentication state
│   ├── session_provider.dart        # Fluid session state
│   ├── schedule_provider.dart       # Schedule management
│   ├── streak_provider.dart         # Streak tracking
│   ├── subscription_provider.dart   # Premium features
│   ├── sync_provider.dart           # Data synchronization
│   └── analytics_provider.dart      # Usage analytics
│
├── features/                        # Feature modules
│   ├── auth/                        # User authentication
│   │   ├── models/                  # Auth data models
│   │   │   ├── app_user.dart        # User model
│   │   │   └── auth_state.dart      # Auth state model
│   │   ├── screens/                 # Auth UI screens
│   │   │   ├── login_screen.dart    # Login interface
│   │   │   ├── register_screen.dart # Registration form
│   │   │   └── forgot_password_screen.dart # Password reset
│   │   ├── widgets/                 # Auth UI components
│   │   └── services/                # Auth business logic
│   │       └── auth_service.dart    # Authentication service
│   ├── onboarding/                  # User onboarding
│   │   ├── models/                  # Onboarding data
│   │   ├── screens/                 # Onboarding flows
│   │   │   ├── welcome_screen.dart  # Welcome intro
│   │   │   ├── pet_setup_screen.dart # Pet configuration
│   │   │   └── schedule_setup_screen.dart # Initial schedule
│   │   └── widgets/                 # Onboarding components
│   ├── home/                        # Main dashboard
│   │   ├── models/                  # Home data models
│   │   ├── screens/                 # Home UI screens
│   │   │   ├── home_screen.dart     # Main dashboard
│   │   │   └── component_demo_screen.dart # UI showcase
│   │   └── widgets/                 # Home components
│   │       ├── streak_display.dart  # Streak counter
│   │       ├── next_session_card.dart # Next session info
│   │       └── quick_actions.dart   # Quick action buttons
│   ├── logging/                     # Session logging
│   │   ├── models/                  # Logging data models
│   │   │   ├── fluid_session.dart   # Fluid session data
│   │   │   └── stress_level.dart    # Stress level enum
│   │   ├── screens/                 # Logging interfaces
│   │   │   ├── logging_screen.dart  # Main logging screen
│   │   │   ├── quick_log_screen.dart # Quick logging
│   │   │   ├── detailed_log_screen.dart # Detailed entry
│   │   │   └── session_history_screen.dart # History view
│   │   └── widgets/                 # Logging components
│   │       ├── volume_input.dart    # Volume selector
│   │       ├── stress_selector.dart # Stress level picker
│   │       └── injection_site_picker.dart # Site selector
│   ├── profile/                     # Pet profile management
│   │   ├── models/                  # Profile data models
│   │   │   ├── cat_profile.dart     # Pet profile data
│   │   │   └── medical_info.dart    # Medical information
│   │   ├── screens/                 # Profile interfaces
│   │   │   ├── profile_screen.dart  # Profile overview
│   │   │   └── medical_details_screen.dart # Medical details
│   │   ├── widgets/                 # Profile components
│   │   └── services/                # Profile services
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
│   │   ├── screens/                 # Progress interfaces
│   │   │   ├── progress_screen.dart # Progress overview
│   │   │   └── detailed_analytics_screen.dart # Analytics (premium)
│   │   └── widgets/                 # Progress components
│   │       ├── adherence_chart.dart # Adherence visualization
│   │       └── stress_trends.dart   # Stress trend charts
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
│   │   │   ├── settings_screen.dart # Settings overview
│   │   │   └── privacy_screen.dart  # Privacy settings
│   │   └── widgets/                 # Settings components
│   ├── exports/ (premium)           # Data export features
│   │   ├── models/                  # Export data models
│   │   ├── screens/                 # Export interfaces
│   │   │   └── export_screen.dart   # Export configuration
│   │   ├── widgets/                 # Export components
│   │   └── services/                # Export services
│   │       └── pdf_export_service.dart # PDF generation
│   ├── inventory/ (premium)         # Supply tracking
│   │   ├── models/                  # Inventory models
│   │   │   └── fluid_inventory.dart # Supply tracking data
│   │   ├── screens/                 # Inventory interfaces
│   │   │   └── inventory_screen.dart # Inventory management
│   │   ├── widgets/                 # Inventory components
│   │   └── services/                # Inventory services
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
│   │   └── sync_item.dart           # Sync data model
│   ├── repositories/                # Data access layer
│   │   ├── base_repository.dart     # Base repository
│   │   ├── session_repository.dart  # Session data access
│   │   ├── profile_repository.dart  # Profile data access
│   │   ├── schedule_repository.dart # Schedule data access
│   │   ├── user_repository.dart     # User data access
│   │   └── analytics_repository.dart # Analytics data
│   ├── services/                    # Core services
│   │   ├── firebase_service.dart    # Firebase integration
│   │   ├── sync_service.dart        # Data synchronization
│   │   ├── notification_service.dart # Push notifications
│   │   ├── reminder_scheduler.dart  # Reminder scheduling
│   │   ├── analytics_service.dart   # Usage analytics
│   │   ├── privacy_service.dart     # Privacy management
│   │   ├── validation_service.dart  # Data validation
│   │   └── backup_service.dart      # Data backup
│   └── widgets/                     # Reusable UI components
│       ├── accessibility/           # Accessibility components
│       │   ├── accessibility.dart   # A11y exports
│       │   ├── hydra_focus_indicator.dart # Focus indicator
│       │   └── hydra_touch_target.dart # Touch target helper
│       ├── buttons/                 # Button components
│       │   ├── buttons.dart         # Button exports
│       │   ├── hydra_button.dart    # Primary button
│       │   ├── hydra_fab.dart       # Floating action button
│       │   └── premium_button.dart  # Premium CTA button
│       ├── cards/                   # Card components
│       │   ├── cards.dart           # Card exports
│       │   ├── hydra_card.dart      # Base card component
│       │   ├── premium_card.dart    # Premium feature card
│       │   └── medical_data_card.dart # Medical info card
│       ├── icons/                   # Icon components
│       │   ├── icons.dart           # Icon exports
│       │   └── hydra_icon.dart      # Custom icon widget
│       ├── forms/                   # Form components
│       │   ├── validated_text_field.dart # Input field
│       │   ├── volume_slider.dart   # Volume selection
│       │   └── time_picker.dart     # Time selection
│       ├── feedback/                # Feedback components
│       │   ├── success_animation.dart # Success animation
│       │   ├── streak_celebration.dart # Streak milestone
│       │   └── offline_indicator.dart # Offline status
│       ├── layout/                  # Layout components
│       │   ├── layout.dart          # Layout exports
│       │   ├── dev_banner.dart      # Development banner
│       │   ├── layout_wrapper.dart  # Main layout wrapper
│       │   ├── screen_wrapper.dart  # Screen container
│       │   ├── section_wrapper.dart # Content sections
│       │   └── premium_wrapper.dart # Premium feature wrapper
│       ├── navigation/              # Navigation components
│       │   ├── navigation.dart      # Navigation exports
│       │   ├── hydra_navigation_bar.dart # Bottom navigation
│       │   └── pet_selector.dart    # Pet selection
│       └── widgets.dart             # Widget exports
│
└── l10n/                            # Internationalization
    ├── app_localizations.dart       # Generated localizations
    ├── app_en.arb                   # English translations
    ├── app_fr.arb                   # French translations
    └── app_de.arb                   # German translations