# HydraCat - Product Requirements Document

## Executive Summary

HydraCat is a specialized mobile application designed to help cat owners manage subcutaneous fluid therapy for cats with chronic kidney disease (CKD). Unlike generic pet care apps, HydraCat focuses specifically on the medical precision, emotional support, and adherence tracking needed for successful fluid therapy management.

## Core Goals

1. **Help owners organize and succeed with fluid therapy** - Provide structured scheduling, logging, and tracking tools
2. **Reduce emotional stress** - For both cats and owners through guided support and positive reinforcement
3. **Encourage compliance and consistency** - Through gamification, reminders, and motivational features
4. **Build goodwill and visibility** - Establish brand presence for future HydraCat device ecosystem
5. **Collect ethical usage data** - Anonymous, opt-in analytics to support product development and research

## Target Audience

### Primary Users
- **Primary Caregivers**: Cat owners managing CKD with prescribed subcutaneous fluid therapy
- **Concerned Family Members**: Secondary users who help with cat care
- **Veterinary-Conscious Owners**: Users who value medical precision and vet-approved guidance

### User Personas
- **Anxious New Caregiver**: Recently diagnosed cat, overwhelmed by treatment complexity
- **Experienced but Inconsistent**: Familiar with procedure but struggling with routine adherence
- **Data-Driven Optimizer**: Wants detailed tracking and insights for veterinary consultations

## Technical Requirements

### Platform Support
- **iOS**: Native Flutter app targeting iOS 12+
- **Android**: Native Flutter app targeting API level 21+
- **Offline Capability**: Full functionality available without internet connection
- **Data Sync**: Automatic synchronization when connectivity restored

### Backend Architecture
- **Firebase Suite**: Authentication, Firestore, Cloud Functions, FCM
- **Firestore-First Design**: All data stored in Firestore with offline persistence
- **Conflict Resolution**: Last write wins for data conflicts
- **Data Privacy**: GDPR-compliant, data minimization principles

## Feature Requirements

### Core Features (MVP)

#### Authentication & Profile Management
**Free Tier:**
- Single pet profile creation
- Basic profile data (name, fluid schedule)
- Logs stored in Firestore (so offline works)
- Only 30 days of history visible
- Only 1 reminder
- Optional registration upgrade path

**Premium Tier:**
- Full Firebase account with cloud sync
- Vet-ready PDF exports
- Up to 5 pet profiles per account
- Complete medical history storage
- Tracking of fluid volume left in storage
- Multiple reminders and notifications
- Cross-device data synchronization

#### Fluid Therapy Scheduling
- **Fixed Schedules**: Same volume, consistent frequency (daily/alternate days)
- **Flexible Timing**: Multiple reminder times per day
- **Volume Targets**: 0-500ml range with validation
- **Future Enhancement**: Variable daily volumes, temporary overrides

#### Session Logging
**Required Data:**
- Date/time of administration (auto-fill with current timestamp, but editable)
- Volume given (ml)
- Treatment completion status

**Optional Data:**
- Stress level (low/medium/high)
- Injection site location
- Session notes/comments
- Duration of treatment
- Weight of the cat (by default, same as initially, updated when new value input)

#### Notifications & Reminders
- **Start-Session Nudges**: Exact scheduled time notifications
- **Grace Period Follow-ups**: Gentle reminders until end of day
- **Missed Session Alerts**: Compassionate tone, end-of-day notification
- **Streak Celebrations**: Positive reinforcement for consistency
- **Weekly Summaries**: Progress overview and encouragemen ("Your weekly summary is ready")


#### Streak System & Gamification
- **Forgiving Streak Logic**: Only breaks after 2 consecutive missed sessions
- **End-of-Day Breaks**: Streaks broken at midnight, not missed appointment time
- **Retroactive Logging**: Users can log missed sessions to maintain streaks
- **Visual Progress**: Prominent display on home screen
- **Health-First Philosophy**: Medical outcomes prioritized over gamification

### Premium Features (€2.99/month)

#### Advanced Analytics
- **30+ Day History**: Complete treatment records
- **Trend Analysis**: Volume patterns, adherence rates, timing analysis
- **Stress Correlation**: Relationship between stress levels and treatment success
- **Monthly/Weekly Reports**: Detailed summaries with visual charts
- **Inventory Tracking**: Fluid quantity monitoring with reorder reminders

#### Professional Integration
- **Vet-Ready PDF Exports**: Professional reports for consultations
- **Extended Data Storage**: Unlimited historical data retention
- **Advanced Insights**: Personalized recommendations based on patterns

#### Multi-Pet Management
- **Up to 5 Cats**: Complete profiles and tracking for multiple pets
- **Comparative Analytics**: Cross-pet insights and management efficiency
- **Individual Scheduling**: Separate routines and notifications per pet

### Future Enhancements (Post-MVP)
- **Interactive Stress-Free Guide**: Video content, step-by-step tutorials
- **Advanced Scheduling**: Variable volumes, vet-directed adjustments
- **Community Features**: Anonymous peer support and tips sharing
- **Creatinine Tracking**: Simple graph showing creatinine level evolution
## User Experience Requirements

Mandatory authentication to use the app (Firebase Authentication)

### Onboarding Flow

#### Minimum Viable Information
1. Pet name
2. Fluid therapy frequency
3. Volume per session
4. Email/password (if registering)

#### Nice-to-Have Information
- Pet sex, age, weight
- Cat photo upload
- CKD diagnosis date
- Disease stage (IRIS staging)
- Veterinary contact (optional)

### Home Screen Layout
- **Primary Focus**: Next scheduled session countdown
- **Streak Display**: Current and longest streak prominently featured
- **Quick Actions**: One-tap session logging
- **Recent History**: Last 3-7 sessions at a glance
- **Cat Switching**: Long-press navbar for multi-pet accounts (Premium)

### Session Logging Interface
- **One-Tap Completion**: Quick "Done" button for routine sessions
- **Detailed Entry**: Expandable form for comprehensive logging
- **Validation**: Volume range checking (0-500ml)
- **Stress Assessment**: Simple emoji-based rating system
- **Injection Site Tracker**: Visual body diagram for site rotation

## Data & Privacy Requirements

### Data Collection Principles
- **GDPR-First Design**: Data minimization by default
- **Optional Information**: Owner full name, address, birthday not collected
- **Minimal Authentication**: Email + pet nickname sufficient
- **Veterinary Data**: Optional storage only when explicitly provided

### Anonymous Analytics (Opt-in)
**Collected Data:**
- Treatment adherence metrics
- Session characteristics (volume ranges, frequency patterns)
- Schedule settings and preferences
- App engagement patterns (feature usage, session duration)
- Stress level trends (aggregated)

**Usage:**
- Product development insights
- Feature optimization
- Research support for veterinary partnerships
- Fundraising and development justification

### Data Security
- **Encryption**: All data encrypted in transit and at rest
- **Firestore Offline**: Built-in offline persistence with automatic sync
- **Access Control**: Firebase security rules preventing cross-user access
- **Data Export**: User-controlled data download for portability

## Business Model

### Free Tier - Core Engagement
**Included Features:**
- Single pet profile
- Basic fluid scheduling and reminders (1 reminder only)
- Session logging with volume tracking
- 30-day history access
- Basic streak system
- Stress level logging
- Last injection site tracking
- Essential tips and guidance

**Limitations:**
- Firestore storage (but with offline capability)
- 30-day history limit
- Single pet maximum
- Single reminder per session
- Limited analytics

### Premium Tier - €2.99/month
**Additional Features:**
- Cloud sync across devices
- Up to 5 pet profiles
- Unlimited history access (complete medical records)
- Advanced analytics and insights
- Vet-ready PDF exports
- Fluid inventory tracking
- Multiple reminders and notifications
- Personalised recommendations
- Inventory tracking
- Priority customer support

**Future Pricing:**
- Annual subscription discount (TBD)
- Family plan considerations
- Veterinary practice licensing (potential)

## Success Metrics

### User Engagement
- **Daily Active Users**: Target 60% of registered users
- **Session Logging Rate**: >80% of scheduled sessions logged
- **Retention**: 70% monthly retention for registered users
- **Streak Participation**: 40% of users maintain 7+ day streaks

### Health Outcomes
- **Treatment Adherence**: Measure improvement vs. baseline
- **Stress Reduction**: Track reported stress level trends
- **Veterinary Value**: PDF export usage and vet feedback

### Business Metrics
- **Free-to-Premium Conversion**: Target 15% conversion rate
- **Churn Rate**: <5% monthly churn for premium subscribers
- **Customer Acquisition Cost**: Optimize through organic growth
- **Lifetime Value**: Track premium subscription duration

## Technical Implementation Priority

### Phase 1 (MVP - 3 months)
1. **Core Authentication**: Firebase Auth with Firestore integration
2. **Basic Scheduling**: Fixed frequency, single daily reminder
3. **Session Logging**: Volume + completion status + basic notes
4. **Simple Analytics**: 30-day history for free users, basic streak tracking
5. **Notification System**: FCM integration for reminders
6. **Offline Support**: Firestore offline persistence and automatic sync

### Phase 2 (Premium Features - 2 months)
1. **Advanced Analytics**: Unlimited history, trend analysis
2. **Multi-Pet Support**: Profile switching, separate schedules
3. **PDF Export**: Vet-ready report generation
4. **Enhanced Notifications**: Multiple reminders and personalized content
5. **Payment Integration**: Subscription management
6. **Inventory Tracking**: Fluid quantity monitoring system

### Phase 3 (Enhancement - 3 months)
1. **Advanced Scheduling**: Variable volumes, temporary overrides
2. **Stress-Free Guide**: Static content with illustrations
3. **Inventory Tracking**: Basic fluid quantity monitoring
4. **Pattern Recognition**: Automated insights and recommendations
5. **Performance Optimization**: App speed and battery efficiency

### Phase 4 (Future Expansion - 6+ months)
1. **Video Content**: Interactive guide with video tutorials
2. **Community Features**: Anonymous peer support
3. **Veterinary Integration**: Direct vet communication features
4. **Supply Chain**: Potential fluid kit ordering system
5. **Advanced Analytics**: Machine learning insights

## Risk Assessment & Mitigation

### Technical Risks
- **Firestore Costs**: Monitor usage patterns and optimize queries
- **Offline Sync Complexity**: Implement robust conflict resolution with Firestore
- **Cross-Platform Consistency**: Extensive testing on both platforms
- **Performance**: Monitor app responsiveness with large datasets
- **Battery Usage**: Optimise notification and background sync

### Business Risks
- **Market Size**: Limited to CKD cat population - focus on excellent UX
- **Competition**: Differentiate through medical specialization
- **Monetization**: Balance free value with premium incentives
- **Regulatory**: Ensure compliance with medical device regulations

### User Experience Risks
- **Complexity Overwhelm**: Prioritize simplicity in core features
- **Gamification Balance**: Ensure health outcomes remain primary focus
- **Privacy Concerns**: Transparent data practices and user control
- **Abandonment**: Strong onboarding and early value demonstration

## User Stories (Agile Framework)

### Authentication & Profile
- As a first-time user, I want to create an account with my email and a password so that I can securely access my cat's health information and track their treatment.
- As a returning user, I don't want to have to log in again to my account so that I can resume tracking my cat's fluid therapy sessions from where I left off.
- As a cat owner, I want to create a profile for my cat with their name, a photo, weight, and fluid prescription so that I have a personalized and organized record of their health data in one place.

### Fluid Schedule & Logging
- As a cat owner, I want to set a custom fluid schedule with specific times and amounts so that I never forget when to give my cat their fluids.
- As a cat owner, I want to log a fluid session with a single tap so that I can quickly and easily record the treatment without disrupting my cat's care routine.
- As a cat owner, I want to see a simple 7-day history of my logged fluid sessions so that I can review my cat's compliance over the past week.

### Notifications & Streak System
- As a cat owner, I want to receive timely notifications for my scheduled fluid sessions so that I can stay on track with my cat's treatment and improve their health.
- As a cat owner, I want to have a simple streak system that tracks my consecutive days of successful fluid therapy so that I feel motivated and rewarded for my consistency.
- As a cat owner, I want to see my current (and longest streak) prominently on the home screen so that I feel a sense of accomplishment and am encouraged to maintain the routine.

### Stress-Free Guide
- As a cat owner, I want a simple guide with essential, vet-approved tips on how to give fluids and handle my cat so that I feel more confident and reduce the stress for both of us.

## Conclusion

HydraCat addresses a specific, underserved market with a focused, medically-aware approach to pet health management. By prioritizing the unique needs of CKD cat owners and their emotional journey, the app can establish strong user loyalty and create a foundation for future expansion into broader pet health technology.

The freemium model balances accessibility with sustainability, while the offline-first architecture ensures reliability in critical health management scenarios. Success will be measured not just in user engagement, but in improved health outcomes and reduced caregiver stress.

---

*This PRD serves as the definitive guide for HydraCat development. All feature decisions and technical implementations should reference this document to maintain product vision alignment and user-centered design principles.*