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

## Semantic refactoring/Identifier Renaming (Code smell detection) ##



##

Please update logging_plan.md to take into consideration what we just implemented in this step for future reference. Particularily add things we would need to remember for future use or implementation. Don't include information related to linting. Keep it as short as possible.

I would like now to complete the full implementation plan for the weight page (~PLANNING/weight_plan.md). We will use fl_chart 1.1.1 (latest version. Here is the documentation for line charts: https://github.com/imaNNeo/fl_chart/blob/main/repo_files/documentations/line_chart.md) for the simple weight chart. Please create a detailled phase/step by step plan with each step that I can tackle in a focused work session assisted by AI (Claude Code or Cursor). You can check other similar plans we did like ~PLANNING/DONE/reminder_plan.md or ~PLANNING/DONE/fcm_daily_wakeup_plan.md. I don't need checklists or time estimates. Don't hesitate to let me know if you think of any meaningful and realistic improvements I might have overlooked. Before you create the plan, please ask any and all questions you have in order to provide the most robust solution to handle edge cases and/or additional context that you might need to feel confident in proceeding with the implementation. When you do use clarifying questions, please do not use bullet points but rather letters within each numbered question if number requires bullet points. Before you ask me questions, please already have a look at all the existing files you would need, as well as previously implemented steps, to already have the context, use existing systems, ensure coherence and in case you already find the answer to your questions. Suggest for each question your recommended solution. Keep in mind that I want to have the best suited solution for my project while being in line with industry standards and app development best practices as much as possible. Please follow Firebase and Flutter best practices and use built-in solutions whenever possible instead of more complex custom/hacky workarounds. Also, keep in mind the CRUD rules file (.cursor/rules/firebase_CRUDrules.md) to make sure to keep firebase costs to a minimum. Regarding database, I don't need to worry about backward compatibility since I will regularily delete the database anyway for testing.

1. Support both edit and delete with no time constraints, following the existing FluidSession update pattern (delta calculations for summary updates). This gives users full control over their data and handles mistakes gracefully. For a) What would that "dialog" look like ?
2. Option (a) - Auto-sync with latest weight entry. When a weight is logged/edited/deleted, update the CatProfile.weightKg field to reflect the most recent value. This maintains backward compatibility and provides quick access to current weight without querying healthParameters.
3. Option (b) - Allow backdating but not future dating. Use a date picker with firstDate: DateTime(2020) and lastDate: DateTime.now(). This handles real-world scenarios like entering weight from recent vet visits while preventing accidental future entries. We already used date pickers for the calendar, we can reuse it for consistency.
4. Option (c) - Adaptive with optional "All Time" button. Start with last 12 months (optimal for monthly summaries), but if user has < 12 months of data, show everything. Add a chip/button to toggle "All Time" view that queries all monthly summaries when needed. This balances cost optimization with flexibility.
5. We already have validation for weight (lib/features/profile/services/profile_validation_service.dart) we used when weight is inputted during onboarding, we should reuse it for consistency/efficiency ? Please let me know if you find it.
6. Option (a) - Include optional notes field. The schema already supports it (healthParameters.notes), and it's valuable for tracking context like "weighed at vet", "after food", "before fluids", etc. Use the same validation as other sessions (500 char limit). We can use a simple line field that can extend when the user press it to write something. I think we also use that somewhere else in the app (I think during logging popup).
7. Option (a) - Real-time batch writes following the exact pattern used for FluidSession/MedicationSession. When logging weight, batch write both healthParameters/{date} and treatmentSummaries/monthly/summaries/{month} using SetOptions(merge: true). This maintains consistency with existing architecture and provides instant graph updates.
8. Option (b) - Show an attractive onboarding card with brief explanation and "Log Your First Weight" button. After first entry, replace with actual graph. This follows UX best practices and helps users understand the feature's value.
9. Option (a) - Store everything in kg (standardized), display using weightUnitProvider. This matches the existing pattern, simplifies calculations, and prevents unit conversion errors. The graph and list respect user's unit preference from settings. Do you still agree, storing weight in kg (even for users that uses lbs) is the right approach ? I also already have some conversion util existing I think.
10. Option (c) - No automatic migration. The CatProfile.weightKg is from onboarding (possibly months old) and shouldn't be backdated. Users can log current weight when ready. If we implement Question 2's sync recommendation, future weight logs will update the profile field anyway. I am still in development so I don't have any users, no backward compatibility needed anyway.
Please let me know if this makes sense or contradict itself, the prd (.cursor/reference/prd.md), the CRUD rules or existing code. Coherence and app development/Flutter best practices are extremely important. Please confirm that this follow industry standards, and if not explain why. Let me know if you need any more clarifications to feel confident in proceeding with the implementation. Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself. After implementation, check for linting issues (flutter analyze) and, if you found any, fix them (including the non critical ones). I will test only once we fixed the linting issues.

