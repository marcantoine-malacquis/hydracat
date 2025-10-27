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


1. Create a focused "Notification Privacy & Data Handling"
  section in assets/legal/notification_privacy.md that can be linked from the
  permission pre-prompt dialog. This keeps it specific to Step 5.4's scope while
   being easily expandable later. We can add a "Privacy Policy" link in the
  notification settings screen.
2. Keep the current approach of only maintaining today's index
   and auto-cleaning yesterday's index at midnight rollover. This is more
  privacy-focused (less data retained) and simpler. Notification settings should
   persist indefinitely since they're user preferences, not sensitive data -
  only clear them on explicit logout or "Clear notification data" action.
3. The "Clear notification data" action should: (a) Cancel all
   currently scheduled notifications, (b) Clear the notification index from
  SharedPreferences, (c) Keep notification settings intact (they're user
  preferences, not "data"), and (d) Keep system permission status intact. This
  provides a "nuclear reset" for the notification system without forcing users
  to reconfigure their preferences or permissions.
4. On logout, cancel all scheduled notifications and clear the
   index, but PRESERVE notification settings in SharedPreferences (keyed by
  userId). This provides better UX - if the user logs back in, their preference
  for enabling/disabling notifications is remembered. Users who want to fully
  clear everything can explicitly use "Clear notification data" before logging
  out.
5. Add a concise privacy notice (2-3 sentences) directly in
  the permission pre-prompt dialog below the existing educational content, with
  a "Learn More" link that opens a bottom sheet or dialog with full privacy
  details. Keep it brief but reassuring - mention generic content, local-only
  storage, and no transmission of medical data.
6. Unless you have specific regulatory requirements, keep it
  simple for this medical pet app: clear privacy notices, reasonable defaults
  (local-only, generic content, minimal retention), and user control options. No
   complex consent flows or audit logging unless legally required.
Please let me know if this makes sense or contradict itself, the prd (.cursor/reference/prd.md), the CRUD rules or existing code. Coherence and app development best practices are extremely important. Let me know if you need any more clarifications to feel confident in proceeding with the implementation. Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself. After implementation, check for linting issues (flutter analyze) and, if you found any, fix them (including the non critical ones). I will test only once we fixed the linting issues.