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

I would like to implement a new screen dedicated to injection sites that would show a pie of the last 20 fluid sessions where each region correspond to an injection site. We would query only the last 20 fluidSessions for the injection site wheel. We would use fl_chart for the pie chart. I want the pie to be like a donut (with an empty space in the middle). I don't really care about the colors for each site, but they need to be complementary and in the same empathetic tone as the current system decribed in /Users/marc-antoinemalacquis/Development/projects/hydracat/.cursor/rules/ui_guidelines.md. Although, I really like pastel colors. The "% (X)" would be integrated in the pie (X being the number of session among the 20) and the legend would be below the pie chart.
The access of this screen would be from a "Injection sites" card in a list on the Progress screen (below the calendar). More items will be added to the list of analytics later on. We can reuse the same card model as the ones found on the Profile screen.
In this new injection sites analytics screen, for now, there would only be the app bar (with back button), nav bar, the chart and legend . I will add more explanation on injection sites later on this screen.
Please create a detailed plan of how you will achieve and implement this new screen. Don't hesitate to let me know if you think of any meaningful and realistic improvements I might have overlooked.
Before you create the plan, please ask any and all questions you have in order to provide the most robust solution to handle edge cases and/or additional context that you might need to feel confident in proceeding with the implementation. When you do use clarifying questions, please do not use bullet points but rather letters within each numbered question if number requires bullet points. Before you ask me questions, please already have a look at all the existing files you would need, as well as previously implemented steps, to already have the context, use existing systems, ensure coherence and in case you already find the answer to your questions. Suggest for each question your recommended solution. Keep in mind that I want to have the best suited solution for my project while being in line with industry standards and app development best practices as much as possible. Please follow Firebase and Flutter best practices and use built-in solutions whenever possible instead of more complex custom/hacky workarounds. Also, keep in mind the CRUD rules file (.cursor/rules/firebase_CRUDrules.md) to make sure to keep firebase costs to a minimum. Regarding database, I don't need to worry about backward compatibility since I will regularily delete the database anyway for testing.


I would actually like for the injection site to be a mandatory field (like the volume) when logging a fluid session. I think this is already the case as it default to one in any case. Please have a look at what is currently implemented.
1. a) let's use dateTime (when treatment
  actually occurred)
  b) query only sessions that have a non-null injectionSite value
c) yes, create a new provider with offline caching to minimize reads.
2. a) show whatever sessions exist with a
  subtitle like "Based on the last X sessions" instead of waiting for 20.
b) Let's just show "Start tracking injection sites to see your rotation pattern" for now. No need for CTA.
c) yes, showing the chart with
   any number of sessions ≥1, as even 1-2 data points provide value.
3. a) yes, let's go with "25%" in the
  pie sections (cleaner look) and "Shoulder blade - left: 5 sessions (25%)"
  in the legend for full context.
b) show only used sites to keep the legend concise and focused.
c) 50-60% (centerSpaceRadius), which creates a clean donut appearance without making the sections too thin.
4. a) 4 distinct pastel colors for better visual
  differentiation while maintaining the empathetic tone.
b) consistent mapping for predictability and easier pattern recognition.
5. a) create a reusable widget to save refactoring time later.
b) the same scroll view for a unified
  experience.
c) "Insights" as a header
6. a) /progress/injection_sites 
b) yes, let's only track screen_view for now
7. a) no need to reserve space for now
Please let me know if this makes sense or contradict itself, the prd (.cursor/reference/prd.md), the CRUD rules or existing code. Coherence and app development/Flutter best practices are extremely important. Please confirm that this follow industry standards, and if not explain why. Let me know if you need any more clarifications to feel confident in proceeding with the implementation. Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself. After implementation, check for linting issues (flutter analyze) and, if you found any, fix them (including the non critical ones). I will test only once we fixed the linting issues.
Once, we I have confirmed that we both align on all of the necessary details, let's create the detailed implementation plan in /Users/marc-antoinemalacquis/Development/projects/hydracat/~PLANNING/injSites_analytics_plan.md

Perfect, please include in the plan a phase to make injection site properly tracking mandatory for logging.
Yes, let's use /progress/injection-sites to follow Flutter routing conventions.
Please the detailed implementation plan.