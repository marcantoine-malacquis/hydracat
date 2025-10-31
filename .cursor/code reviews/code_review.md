 🔍 HydraCat Codebase Coherence Analysis

  You are an expert code reviewer and optimiser. Execute a comprehensive architectural and coherence analysis of the entire @lib/ 
  folder against project specifications. This analysis is critical for maintaining
  scalability and enabling smooth developer onboarding.

  📋 Analysis Scope

Primary Focus Areas:
1. Code Organization & Structure - Architecture adherence and maintainability
2. Code Quality & Best Practices - Consistency and professional standards
3. Naming Conventions - Semantic naming rules compliance for identifiers
4. UI/UX Implementation Coherence - Design system compliance and scalability
5. Firebase Integration Standards - Cost optimization and performance
6. Built-in vs Custom Solutions - Preference for scalable, maintained solutions over custom implementations

  🎯 Reference Documents Analysis

  Compare all code in @lib/ against these specifications:
  - @.cursor/reference/prd.md - Product requirements and feature specifications
  - @.cursor/rules/firebase_CRUDrules.md - Firebase cost optimization guidelines
  - @.cursor/rules/ui_guidelines.md - Design system and UI/UX standards
  - @.cursor/code reviews/semantic_rules.md - Naming conventions and semantic rules

  🔬 Detailed Analysis Requirements

1. Architectural Coherence

- Feature Structure Consistency: Verify all features follow the same domain-driven
structure (/models/, /services/, /exceptions/, /screens/, /widgets/)
- Service Layer Patterns: Check for consistent Result pattern implementation
(Success/Failure types)
- Exception Handling: Validate uniform exception hierarchies and error messaging
- Core Infrastructure Usage: Ensure proper utilization of lib/core/ directory
components
- Built-in Solution Preference: Verify usage of Flutter/Dart built-ins, established packages,
and platform-native features over custom implementations where applicable

  2. Naming Conventions Compliance
  
  - Boolean Variables: Check all boolean getters/variables use proper prefixes (is, has, should, can, was)
  - Method Names: Verify async methods use clear action verbs (get, fetch, save, update, delete)
  - Variable Naming: Identify generic names (data, value, temp, flag) that need context-specific replacements
  - Consistency Patterns: Check for naming consistency within files and across related methods
  - Serialization Patterns: Verify proper suffixes for data transfer (*Data, *Payload, *Json, *Map)

  3. Firebase Implementation Compliance

  - Query Optimization: Check for proper .limit(), pagination, and .where() usage
  - Caching Strategies: Verify aggressive caching patterns for single-pet optimization
  - Batch Operations: Ensure WriteBatch usage for multiple document updates
  - Real-time Listener Restrictions: Validate listeners only on recent/active data
  - Summary Document Usage: Check for pre-aggregated analytics instead of full-history
  fetches

  4. UI/UX Design System Adherence

  - Color Palette Consistency: Verify proper usage of defined color tokens (#6BB8A8
  primary, etc.)
  - Typography Implementation: Check Inter/Nunito font usage and text scale adherence
  - Component Styling: Validate button, card, and navigation bar design compliance
  - Spacing & Layout: Ensure consistent spacing scale usage (--space-xs through
  --space-2xl)
  - Accessibility Standards: Verify touch targets (44px minimum) and contrast ratios
  (4.5:1)

  5. Feature-Specific PRD Compliance

  - Treatment Approach Logic: Verify fluid therapy vs. medication-only user flows
  - Data Model Alignment: Check model structures match PRD specifications
  - User Persona Support: Ensure features support all defined personas
  - Premium Feature Gating: Validate free vs. premium feature boundaries

6. Developer Experience & Scalability

- Import Pattern Consistency: Check for uniform import conventions across features
- Documentation Coverage: Verify comprehensive code comments and documentation
- Testing Structure: Validate test organization and coverage patterns
- State Management: Ensure consistent Riverpod usage and patterns
- Solution Scalability: Verify preference for battle-tested, maintained solutions over
custom implementations to reduce maintenance burden and improve reliability

  📊 Required Report Format

  Structure the analysis report as follows:

  # HydraCat Codebase Coherence Analysis Report
  Date: [Current Date]

  ## Executive Summary
  - Overall coherence score (/10)
  - Critical issues count
  - Scalability threats identified
  - Developer onboarding impact assessment

  ## 🔥 Critical Scalability Threats
  ### Theme 1: [e.g., "Architectural Inconsistencies"]
  1. **[Highest Threat]** - Description, files affected, scaling impact
  2. **[Second Threat]** - Description, files affected, scaling impact

  ### Theme 2: [e.g., "Firebase Cost Risks"]
  1. **[Highest Threat]** - Description, files affected, scaling impact
  2. **[Second Threat]** - Description, files affected, scaling impact

  ## 🟨 Moderate Issues
  ### Theme: [e.g., "UI/UX Inconsistencies"]
  - Issues ordered by scaling impact
  - Specific file locations and recommendations
  
  ### Theme: [e.g., "Naming Convention Violations"]
  - Boolean variables missing required prefixes
  - Generic variable names needing context
  - Method names lacking clarity

  ## 🟢 Minor Improvements
  ### Theme: [e.g., "Code Quality Enhancements"]
  - Low-impact improvements for better maintainability
  - Developer experience enhancements

  ## 📈 Scalability Recommendations
  1. **Immediate Actions** (Critical for scaling)
  2. **Short-term Improvements** (Enhance maintainability)
  3. **Long-term Enhancements** (Optimize developer onboarding)

  ## 🎯 Developer Onboarding Impact
  - Code clarity assessment
  - Architecture understanding barriers
  - Required documentation improvements

  🎯 Success Criteria

The analysis should identify:
- ✅ All architectural pattern deviations that could confuse new developers
- ✅ Naming convention violations that reduce code clarity and searchability
- ✅ Firebase usage patterns that could cause cost scaling issues
- ✅ UI/UX implementation gaps that break design system coherence
- ✅ Feature implementations that deviate from PRD specifications
- ✅ Code quality issues that impact maintainability and team velocity
- ✅ Custom implementations that should be replaced with built-in or established solutions
- ✅ Opportunities to leverage Flutter/Dart ecosystem and platform-native capabilities

  Prioritization Logic:
  1. Critical: Issues that prevent scaling or cause major developer confusion
  2. Moderate: Issues that slow development or create maintenance debt
  3. Minor: Improvements that enhance code quality but don't block progress

  🔄 Analysis Execution Instructions

  1. Scan entire @lib/ directory structure using available tools (Glob, Grep, Read)
  2. Cross-reference against all specification documents
  3. Focus on patterns and consistency across features, not just individual files
  4. Prioritize issues by potential impact on team scalability
  5. Provide specific file locations and concrete recommendations
  6. Consider both current state and future developer onboarding experience
