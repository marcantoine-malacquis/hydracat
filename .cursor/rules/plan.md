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

Please let me know if this makes sense or contradict itself, the prd (.cursor/reference/prd.md), the CRUD rules (.cursor/rules/firebase_CRUDrules.md) or existing code. Coherence and app development/Flutter best practices are extremely important. Please confirm that this follow industry standards, and if not explain why. Let me know if you need any more clarifications to feel confident in proceeding with the implementation. Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself. After implementation, check for linting issues (flutter analyze) and, if you found any, fix them (including the non critical ones). I will test only once we fixed the linting issues.

I want an implementation plan in phases divided into steps that I can tackle easily with the help of Cursor/Claude Code in a work session.

Please update and add only the important informations to remember about what we implemented in this step for future reference in 

Please follow Firebase and Flutter best practices and use built-in solutions whenever possible instead of more complex custom solutions.
Please let me know if what we have just achieved is the industry standard and most appropriate way to implement this. Let me know in case it is a hacky workaround that will cause issue in the future while scaling the app while another solution would have been more align with best practices and future-proof.

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

Please identify why this is not working as intended and come up with the most robust plan following best practices to fix this issue properly.

1. a) yes, store dailyVolumes (ml per day) and also dailyGoals and dailyScheduledSessions for richer dots/tooltips
b) fixed-length List<int> of size monthLength (up to 31) for compact storage; missing days = 0. This also keeps doc small and predictable.
2. a) yes—extend the existing daily-summary write/update flow to also set dailyVolumes[dayIndex] (and optional goal/scheduled arrays) using the already computed daily totals; never query sessions for aggregation
3. a) yes—whenever daily summary is recomputed/written, overwrite that day’s entry in the monthly summary from the recomputed daily totals to keep it consistent.
4. a) Yes, use dailyScheduledSessions and compute status from monthly doc alone
5. a) yes—keep a short-lived flag for dev, but plan to rely solely on monthly doc for month mode once write path is live.
6. a) add lightweight pure-Dart tests for monthly summary update logic to guard regressions; manual UI verification for the month chart/dots is fine.
Please let me know if this makes sense or contradict itself, the prd (.cursor/reference/prd.md), the CRUD rules (.cursor/rules/firebase_CRUDrules.md) or existing code. Coherence and app development/Flutter best practices are extremely important. Please confirm that this follow industry standards, and if not explain why. Let me know if you need any more clarifications to feel confident in proceeding with the implementation. Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself. After implementation, check for linting issues (flutter analyze) and, if you found any, fix them (including the non critical ones). I will test only once we fixed the linting issues.