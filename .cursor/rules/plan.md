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

Please let me know if this makes sense or contradict itself, the prd (.cursor/reference/prd.md), the CRUD rules or existing code. Coherence and app development/Flutter best practices are extremely important. Please confirm that this follow industry standards, and if not explain why. Let me know if you need any more clarifications to feel confident in proceeding with the implementation. Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself. After implementation, check for linting issues (flutter analyze) and, if you found any, fix them (including the non critical ones). I will test only once we fixed the linting issues.

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


1. a)gate rescheduleAll() and weekly summary scheduling behind auth + onboarding + primary pet; allow index cleanup to run regardless (safe, cheap, local-only).
b) on resume, rely on current user state only; don’t clear indexes for the previous user beyond yesterday purge (cheap and already per-user-keyed). This avoids cross-user coupling and unnecessary writes.
2. a) keep a small persisted value (e.g., last_scheduler_run_yyyy-mm-dd) so that resume after process death still catches a date change; also keep an in-memory fast path to avoid repeated work within the same day/session.
b) treat timezone change as a “date change equivalent” if tz.local offset has changed since last run; then rescheduleAll() just like at midnight rollover. Persist last-known timezone offset minutes; compare on resume.
3. a) implement both for robustness. Schedule a one-shot Timer to next midnight; also run the same logic in resume if date changed since last processing. For DST midnights, compute next midnight using tz-aware helper with tz.local. If the app is killed, resume-time detection still covers it.
b) both. Clear yesterday indexes, then call rescheduleAll() and idempotently reschedule weekly summary. This ensures we don’t rely on users to resume the app for the new day’s schedule to be built.
4. a) call cancelWeeklySummary() then scheduleWeeklySummary() (your rescheduleAll() already does this). On resume, when date/offset changed, just call rescheduleAll() which already includes weekly summary maintenance. This keeps logic centralized.
5. a) yes. If not already done, add a unified “onLogoutCleanup” that cancels all plugin notifications for the session (meds, fluids, snooze, weekly) and clears today’s index for the current user/pet; existing code already clears settings; align cleanup here for consistency.
b) yes. On app start, if persisted last-run date != today, run the same date change path as resume (clear yesterday, reschedule all).
6. a) defer rescheduleAll() until the minimal preconditions hold (auth, onboarding, primary pet present). If not ready on resume, register a one-time post-frame/retry to re-check in a short delay, then run when ready. This avoids no-op or partial state work.
b) add a lightweight in-memory guard in AppShell (e.g., _isRescheduling = true) with a 1-shot debounced execution. ReminderService.rescheduleAll() is idempotent, but this avoids unnecessary work bursts.
7. a) yes; low cost and high diagnostic value. Add in dev-friendly logging as I already do.
8. a) single retry with small backoff (e.g., 2–5 seconds) and then fail-open; subsequent app resume or next lifecycle event will try again. Record error via Crashlytics in production.
Please let me know if this makes sense or contradict itself, the prd (.cursor/reference/prd.md), the CRUD rules or existing code. Coherence and app development/Flutter best practices are extremely important. Please confirm that this follow industry standards, and if not explain why. Let me know if you need any more clarifications to feel confident in proceeding with the implementation. Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself. After implementation, check for linting issues (flutter analyze) and, if you found any, fix them (including the non critical ones). I will test only once we fixed the linting issues.
