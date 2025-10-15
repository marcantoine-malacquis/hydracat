---
description: Ask clarifying questions
    - "**/*"

alwaysApply: false
---
After analysing the situation and looking at the relevant code, please come up with the most appropriate plan, following app development best practices, to fix this issue. Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself.

After analysing the situation and looking at the relevant code, please ultrathink to come up with the most appropriate plan to fix this issue. Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself.

Please ultrathink to come up with the most appropriate plan to achieve this. After analysing the situation and looking at the relevant code, please ask me any question you would need to feel confident about solving the issues. Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself.

Please create a detailed plan of how you will achieve and implement this step.
Before you create the plan, please ask any and all questions you have in order to provide the most robust solution to handle edge cases and/or additional context that you might need to feel confident in proceeding with the implementation. When you do use clarifying questions, please do not use bullet points but rather letters within each numbered question if number requires bullet points. Before you ask me questions, please already have a look at all the existing files you would need, as well as previously implemented steps, to already have the context, use existing systems, ensure coherence and in case you already find the answer to your questions. Suggest for each question your recommended solution. Keep in mind that I want to have the best suited solution for my project while being in line with industry standards and app development best practices as much as possible. Please follow Firebase and Flutter best practices and use built-in solutions whenever possible instead of more complex custom/hacky workarounds. Also, keep in mind the CRUD rules file (.cursor/rules/firebase_CRUDrules.md) to make sure to keep firebase costs to a minimum. Regarding database, I don't need to worry about backward compatibility since I will regularily delete the database anyway for testing.

Please let me know if this makes sense or contradict itself, the prd (prd.md), the CRUD rules or existing code. Coherence and app development best practices are extremely important. Let me know if you need any more clarifications to feel confident in proceeding with the implementation. Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself. After implementation, check for linting issues (flutter analyze) and, if you found any, fix them. I will test only once we fixed the linting issues.

Please update and add only the important informations to remember about what we implemented in this step for future reference in 

Please follow Firebase and Flutter best practices and use built-in solutions whenever possible instead of more complex custom solutions.

Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself.

## Review prompt example ##
  
I would like to review the code related my onboarding feature in @onboarding/ to identify inconsistencies or dead code meaning:
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




I would like on the @progress_screen.dart to display an horizontal calendar (using the table calendar package @https://pub.dev/packages/table_calendar ) right under the app bar, a bit similar to what's on the image. The week will be shown from monday (MON) to sunday (SUN) and the user can press on the any of the day to access which treatment or what fluid volume was admministered on that day. I want for each of the 7 days on that calendar to display a single : green dot (treatment fully administered as per schedule), red dot (treatment not fully administered as per schedule), golden dot (current day), no dot (following days that week). 
Please create a detailed implementation plan of how you will achieve and implement this in @progress_calendar_plan.md. Here are other examples of my previous plans for reference @onboarding_profile_plan.md @logging_plan.md .
Before you create the plan, please ask any and all questions you have in order to provide the most robust solution to handle edge cases and/or additional context that you might need to feel confident in proceeding with the implementation. When you do use clarifying questions, please do not use bullet points but rather letters within each numbered question if number requires bullet points. Before you ask me questions, please already have a look at all the existing files you would need, as well as previously implemented steps, to already have the context, use existing systems, ensure coherence and in case you already find the answer to your questions. Suggest for each question your recommended solution. Keep in mind that I want to have the best suited solution for my project while being in line with industry standards and app development best practices as much as possible. Please follow Firebase and Flutter best practices and use built-in solutions whenever possible instead of more complex custom/hacky workarounds. Also, keep in mind the CRUD rules file (.cursor/rules/firebase_CRUDrules.md) to make sure to keep firebase costs to a minimum. Regarding database, I don't need to worry about backward compatibility since I will regularily delete the database anyway for testing. I have also added more links about the calendar package documentation and a few code examples, let me know if you have all the information you need from there or if you need me to search for more information: @https://pub.dev/documentation/table_calendar/latest/ . @range_example.dart @multi_example.dart @events_example.dart @complex_example.dart @basics_example.dart 

1. a) yes, it should mean “all scheduled treatments for that day were completed” across both medication and fluid. Green only if all scheduled items for that date are satisfied: medicationTotalDoses == medicationScheduledDoses AND fluidSessionCount == scheduledFluidSessions(for that date); if a treatment type isn’t scheduled that day, it doesn’t affect the result.
b) yes, session-count completion for now.
2. a) yes, no dots for Past days with zero schedules
b) yes, golden dot
3. a) golden until we reach “all scheduled treatments for that day were completed”, it is then updated to green to reflect that
4. a) yes, hide dots on all future days in that week.
5. a) for now, let's have a pop-up (blurred background like we already implemented for logging) that shows the treatments that were logged that day. We can maybe reuse cards from the home screen dashboard to show each medication (for each reminder time) and the fluid total that day.
b) pop-up that show a planned view (read-only) with schedules for that date
6) a) perfect! For past days, we’ll read up to 7 DailySummary docs for the visible week via SummaryService.getDailySummary() (benefits from its in-memory TTL caches). If a day has schedules but no daily summary, we treat it as missed (red). For computing scheduled counts we’ll use already preloaded schedules from ProfileProvider and Schedule.reminderTimesOnDate(date).
b) yes, For the day-detail screen, we’ll fetch sessions with a single per-type date-range query (>= startOfDay, < endOfDay) and limit to a safe upper bound (e.g., 50), using Firestore offline cache.
7. a) calendarFormat: CalendarFormat.week, startingDayOfWeek: StartingDayOfWeek.monday, minimal header (month + chevrons), row height ~64–72 for touch targets. Follow @ui_guidelines.md if needed.
b) Recommended colors: green = Colors.green[500], red = Colors.red[500], gold = Colors.amber[600] (we’ll expose via theme constants).
8. yes, add table_calendar: ^3.2.0 . Do you need anymore documentation for it ?
9. a) yes, primary pet only for now
10. a) add Semantics(label: 'Completed day', 'Missed day', 'Today', 'No status') on markers; colors remain as visual-only.

