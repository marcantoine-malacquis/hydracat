# HydraCat - Flutter App Architecture

## Overview
This document outlines the complete architecture of the HydraCat Flutter application's `lib/` directory structure.

## Directory Structure

### Root Level Files
- `main.dart` - Application entry point
- `firebase_options.dart` - Firebase configuration
- `current_arch.md` - This architecture documentation

### 1. App Layer (`lib/app/`)
Core application configuration and routing
- `app.dart` - Main app widget and configuration
- `app_shell.dart` - App shell/layout wrapper
- `router.dart` - Navigation routing configuration

### 2. Core Layer (`lib/core/`)
Foundation components and utilities

#### Constants (`lib/core/constants/`)
- `constants.dart` - Main constants barrel file
- `app_accessibility.dart` - Accessibility-related constants
- `app_colors.dart` - Color palette and theme colors
- `app_icons.dart` - Icon definitions and mappings
- `app_strings.dart` - Localized string constants

#### Theme (`lib/core/theme/`)
- `theme.dart` - Theme barrel file
- `app_theme.dart` - Main theme configuration
- `app_layout.dart` - Layout-related theme settings
- `app_shadows.dart` - Shadow and elevation styles
- `app_spacing.dart` - Spacing and margin constants
- `app_text_styles.dart` - Typography styles
- `README.md` - Theme documentation

#### Extensions (`lib/core/extensions/`)
- `string_extensions.dart` - String utility extensions

#### Utils (`lib/core/utils/`)
- `date_utils.dart` - Date manipulation utilities

#### Exceptions (`lib/core/exceptions/`)
- `app_exception.dart` - Custom exception classes

### 3. Features Layer (`lib/features/`)
Feature-specific modules organized by domain

#### Authentication (`lib/features/auth/`)
- `models/` - Authentication data models
- `screens/` - Authentication UI screens
  - `login_screen.dart` - Login interface
- `widgets/` - Authentication-specific widgets

#### Home (`lib/features/home/`)
- `screens/` - Home-related screens
  - `home_screen.dart` - Main home interface
  - `component_demo_screen.dart` - Component showcase

#### Profile (`lib/features/profile/`)
- `screens/` - Profile management
  - `profile_screen.dart` - User profile interface

#### Progress (`lib/features/progress/`)
- `screens/` - Progress tracking
  - `progress_screen.dart` - Progress display

#### Resources (`lib/features/resources/`)
- `screens/` - Resource management
  - `resources_screen.dart` - Resources interface

#### Schedule (`lib/features/schedule/`)
- `screens/` - Scheduling functionality
  - `schedule_screen.dart` - Schedule interface

#### Logging (`lib/features/logging/`)
- `screens/` - Logging and monitoring
  - `logging_screen.dart` - Logs display

### 4. Shared Layer (`lib/shared/`)
Reusable components and services

#### Models (`lib/shared/models/`)
- Shared data models used across features

#### Repositories (`lib/shared/repositories/`)
- Data access layer implementations

#### Services (`lib/shared/services/`)
- `firebase_service.dart` - Firebase integration service

#### Widgets (`lib/shared/widgets/`)
Reusable UI components

##### Accessibility (`lib/shared/widgets/accessibility/`)
- `accessibility.dart` - Accessibility barrel file
- `hydra_focus_indicator.dart` - Focus indicator component
- `hydra_touch_target.dart` - Touch target wrapper

##### Buttons (`lib/shared/widgets/buttons/`)
- `buttons.dart` - Buttons barrel file
- `hydra_button.dart` - Primary button component
- `hydra_fab.dart` - Floating action button

##### Cards (`lib/shared/widgets/cards/`)
- `cards.dart` - Cards barrel file
- `hydra_card.dart` - Card component

##### Icons (`lib/shared/widgets/icons/`)
- `icons.dart` - Icons barrel file
- `hydra_icon.dart` - Icon component

##### Layout (`lib/shared/widgets/layout/`)
- `layout.dart` - Layout barrel file
- `layout_wrapper.dart` - Layout wrapper component
- `screen_wrapper.dart` - Screen wrapper component
- `section_wrapper.dart` - Section wrapper component

##### Navigation (`lib/shared/widgets/navigation/`)
- `navigation.dart` - Navigation barrel file
- `hydra_navigation_bar.dart` - Navigation bar component

### 5. Localization (`lib/l10n/`)
- Internationalization and localization files

## Architecture Patterns

### Feature-First Organization
- Each feature is self-contained with its own models, screens, and widgets
- Features can be developed and tested independently
- Clear separation of concerns between features

### Shared Component Library
- Reusable widgets in the shared layer
- Consistent design system through shared components
- Accessibility-first approach with dedicated accessibility components

### Core Foundation
- Centralized constants, themes, and utilities
- Consistent styling and behavior across the app
- Extensible architecture for future features

### Clean Architecture Principles
- Clear separation between UI, business logic, and data layers
- Dependency injection through providers
- Repository pattern for data access

## File Naming Conventions
- Feature directories use lowercase with underscores
- Dart files use snake_case
- Barrel files (index files) use the feature name (e.g., `buttons.dart`)
- Component files are prefixed with `hydra_` for shared widgets

## Dependencies
- Flutter framework
- Firebase services
- State management (providers)
- Custom design system components
