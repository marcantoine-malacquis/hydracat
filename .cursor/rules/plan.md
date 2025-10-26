---
description: Ask clarifying questions
    - "**/*"

alwaysApply: false
---
After analysing the situation and looking at the relevant code, please come up with the most appropriate plan, following app development best practices, to fix this issue. Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself.

After analysing the situation and looking at the relevant code, please ultrathink to come up with the most appropriate plan to fix this issue. Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself.

Please ultrathink to come up with the most appropriate plan, following app development best practices, to achieve this. After analysing the situation and looking at the relevant code, please ask me any question you would need to feel confident about the implementation. Suggest for each question your recommended solution. After implementation, check for linting issues (flutter analyze) and, if you found any, fix them. Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself.

Please create a detailed plan of how you will achieve and implement this step. Don't hesitate to let me know if you think of any meaningful and realistic improvements I might have overlooked.
Before you create the plan, please ask any and all questions you have in order to provide the most robust solution to handle edge cases and/or additional context that you might need to feel confident in proceeding with the implementation. When you do use clarifying questions, please do not use bullet points but rather letters within each numbered question if number requires bullet points. Before you ask me questions, please already have a look at all the existing files you would need, as well as previously implemented steps, to already have the context, use existing systems, ensure coherence and in case you already find the answer to your questions. Suggest for each question your recommended solution. Keep in mind that I want to have the best suited solution for my project while being in line with industry standards and app development best practices as much as possible. Please follow Firebase and Flutter best practices and use built-in solutions whenever possible instead of more complex custom/hacky workarounds. Also, keep in mind the CRUD rules file (.cursor/rules/firebase_CRUDrules.md) to make sure to keep firebase costs to a minimum. Regarding database, I don't need to worry about backward compatibility since I will regularily delete the database anyway for testing.

Please let me know if this makes sense or contradict itself, the prd (.cursor/reference/prd.md), the CRUD rules or existing code. Coherence and app development best practices are extremely important. Let me know if you need any more clarifications to feel confident in proceeding with the implementation. Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself. After implementation, check for linting issues (flutter analyze) and, if you found any, fix them (including the non critical ones). I will test only once we fixed the linting issues.

Please update and add only the important informations to remember about what we implemented in this step for future reference in 

Please follow Firebase and Flutter best practices and use built-in solutions whenever possible instead of more complex custom solutions.

Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself.

## Review prompt example ##
  
I would like to review the code related my ... feature in ... to identify inconsistencies or dead code meaning:
- two different ways of achieving the same thing
- custom solutions when simpler and future-proof Flutter/Dart built-in solutions exist
- dead code (code that isn't actually used anywhere)
- deviance from industry-standards
- documentation reflects actual code
- incoherence with @prd.md @firebase_CRUDrules.md
- wrong use of the file architecture including code present in @core/ 
- useless dependencies when more robust methods could be implemented instead 

Please also use the useful guidelines in @code_review.md to make sure the code is up to my standards.
Basically, I want to make sure the onboarding code is production ready, follow best practices, industry-standards whenever possible so I can share it in the future with a developper team that will understand it easily.
After your careful and detailled analysis, please write your result in ... before we tackle each fix one by one.
I already did something similar in @onboarding_code_review_report.md . I don't need to know how long it would take to fix the issue. I don't need a checklist. Regarding database, I don't need to worry about backward compatibility since I will regularily delete the database manually anyway for testing throughout the development.

##

Please update logging_plan.md to take into consideration what we just implemented in this step for future reference. Particularily add things we would need to remember for future use or implementation. Don't include information related to linting. Keep it as short as possible.



1. a) Option A - Show an empathetic dialog explaining the
  medical importance ("Never miss critical treatment times for [PetName]"), with
   a clear "Open Settings" button.
b) Option B - Navigate to notification settings screen
  (which you'll build in Phase 5, Step 5.3)
2. Place it alongside the ConnectionStatusWidget.
3. a) yes, sorry I meant a bell icon. Option A - Icons.notifications and
  Icons.notifications_off. These are universally recognized, accessible, and
  match platform conventions.
b) Yes. Use green/primary color when granted, grey/warning
  color when denied. 
4. a) Show the icon in ALL states with different visuals:
  - granted: Normal bell icon (green/primary color)
  - denied/notDetermined: Barred bell icon (grey/warning color) - tappable to
  request/explain
  - permanentlyDenied (Android only): Barred bell with more urgent color
  (orange) - tappable to open Settings
b) Use isNotificationEnabledProvider (combined state). If
  user has permission but disabled notifications in-app settings, show the
  barred icon. This gives users one clear place to understand notification
  status.
5. a) Yes. Show context-appropriate messages:
  - Permission denied → "Enable notifications in Settings to receive treatment
  reminders"
  - Setting disabled → "Notifications are disabled in app settings" with button
  to settings screen
  - Both → "Enable notifications in Settings, then turn them on in app settings"
6. a) just create a placeholder/navigation for future
   implementation
7. Yes. Track notification_icon_tapped with parameters:
  permission_status, action_taken (opened_settings,
  navigated_to_settings_screen, dismissed). This helps understand friction in
  permission flow.
Please let me know if this makes sense or contradict itself, the prd (.cursor/reference/prd.md), the CRUD rules or existing code. Coherence and app development best practices are extremely important. Let me know if you need any more clarifications to feel confident in proceeding with the implementation. Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself. After implementation, check for linting issues (flutter analyze) and, if you found any, fix them (including the non critical ones). I will test only once we fixed the linting issues.
