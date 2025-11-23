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


1. I want for each symptom a slider going from N/A, then 0, until 10. This reflect the severity "on a scale from 0 to 10"
2. We don't have the appetite tracking implemented yet. For now, we will treat it as "suppressed appetite" as a symptom. We might implement something more complex specifically for it later on.
I want for the first version : vomiting, diarrhea, constipation, lethargy, suppressed appetite and injection site reaction. More will be added later. Probably later including the ability for the owner to add a custom symptom.
3. A "Symptoms" card added to the insights list on the progress screen. It will lead to a new Symptoms screen (empty for now). Let's use the features/health module, reusing the patterns of the weight feature.
4. yes, a) keep the one-doc-per-day pattern you already use for weight and treat symptoms as an editable daily snapshot; this minimizes writes, matches the existing HealthParameter model, and makes summary logic much simpler.
5. yes, c) store both simple boolean-derived counts (cheap and intuitive) and a compact numeric “symptom score” in the daily/weekly/monthly summaries; this keeps reads low (only summary docs) while giving you rich, flexible analytics later.
6. a) use daily data only for a recent window (e.g. last 30 days) and rely on weekly/monthly summary docs for anything longer
7. a) keep the logic in Flutter for now, mirroring what you already do for weight and treatment summaries; this reuses your current patterns, keeps behavior easier to reason about for offline use, and avoids adding server complexity until necessary.
8. a) Yes, a) rely strictly on summary collections for long-range analytics; if you later want deep drill-down, we can fetch small windows of healthParameters on demand (e.g. “tap a month → fetch that month’s days”), still within CRUD rules.
9. a) design for summaries + short-window client-side filtering; if we later need more complex symptom-specific queries, we can add targeted composite indexes (e.g. hasSymptoms + date + petId, or symptoms.vomiting + date + petId) without changing the data model.
10. a) make basic symptom tracking (daily inputs + key trend charts) free, and if you ever gate anything, gate only advanced analytics views; this keeps the app empathetic and patient-centered while still leaving room for monetization later.
11. a) Minimal: symptoms_log_created and symptoms_log_updated events, with anonymized parameters like number of symptoms marked and whether the day is “concerning”, wired through your existing analytics_provider.
Please let me know if this makes sense or contradict itself, the prd (.cursor/reference/prd.md), the CRUD rules or existing code. Coherence and app development/Flutter best practices are extremely important. Please confirm that this follow industry standards, and if not explain why. Let me know if you need any more clarifications to feel confident in proceeding with the implementation. Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself. After implementation, check for linting issues (flutter analyze) and, if you found any, fix them (including the non critical ones). I will test only once we fixed the linting issues.

