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

Let's redesign the pet information card. There should be on the right, for now, a placeholder circle (where the user will have the option to add their cat's photo in the futurer). On the right :
- first line (pet name, symbole for the gender)
- second line (age)
- third line (breed, current weight)
Remove IRIS stage here so it doesn't feel as scary

1. yes, let's use the actual gender symbol. No color-code to avoid stereotypical. It can simply be the app teal color.
2. Yes, let's use "10y • Born May 2015"
3. weight tracking will be a premium feature so let's keep "6.00 kg"
4. The breed field is optional during onbarding. Instead of unknown, simply don't display it if it has not been field during onboarding (instead of "Unknown")
5. yes, show a paw icon inside the circle. Make it subtly tappable (with a small camera icon overlay) for future photo upload.
6. No health indicator, this is simply the pet information so let's not make it scary
Please create a detailed plan of how you will achieve and implement this new screen. Don't hesitate to let me know if you think of any meaningful and realistic improvements I might have overlooked.
Before you create the plan, please ask any and all questions you have in order to provide the most robust solution to handle edge cases and/or additional context that you might need to feel confident in proceeding with the implementation. When you do use clarifying questions, please do not use bullet points but rather letters within each numbered question if number requires bullet points. Before you ask me questions, please already have a look at all the existing files you would need, as well as previously implemented steps, to already have the context, use existing systems, ensure coherence and in case you already find the answer to your questions. Suggest for each question your recommended solution. Keep in mind that I want to have the best suited solution for my project while being in line with industry standards and app development best practices as much as possible. Please follow Firebase and Flutter best practices and use built-in solutions whenever possible instead of more complex custom/hacky workarounds. Also, keep in mind the CRUD rules file (.cursor/rules/firebase_CRUDrules.md) to make sure to keep firebase costs to a minimum. Regarding database, I don't need to worry about backward compatibility since I will regularily delete the database anyway for testing.

1. Option (a) - Add dateOfBirth: DateTime? to CatProfile,
  update the toCatProfile() conversion, and persist it. This gives accurate
  age calculations and better UX. Since you don't care about backward
  compatibility, this is clean.
2. b) Show month + year: "10y • Born May 2015"
3. b) Do nothing (purely visual for now)
4. Option (a) - Extract to
  lib/features/profile/widgets/pet_info_card.dart. Keeps profile_screen.dart
   cleaner and makes the component more maintainable.
5. c) No analytics needed for this change
6. a) Show only weight: "6.0 kg"
Please let me know if this makes sense or contradict itself, the prd (.cursor/reference/prd.md), the CRUD rules or existing code. Coherence and app development/Flutter best practices are extremely important. Please confirm that this follow industry standards, and if not explain why. Let me know if you need any more clarifications to feel confident in proceeding with the implementation. Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself. After implementation, check for linting issues (flutter analyze) and, if you found any, fix them (including the non critical ones). I will test only once we fixed the linting issues.


I was thinking of adding a bar chart showing the volume administered each day of the week with an horizontal bar representing the scheduled session goal. The thing is that I was thinking of adding it right below the calendar so each bar could be perfectly aligned with each day of the week in the calendar. But I just realised that this might need some expensive firestore costs (even with the existing preagregated summaries) if this is displayed every time the user navigate to the progress screen (easily accessible from the navigation bar) so it might be better in a separate screen but we would lose that calendar visual alignement. What do you think I should do ?

Awesome ! I would like to implement this bar chart (using fl_chart package) showing the volume administered each day of the week with an overall horizontal bar representing the scheduled goal. I would like for the bars to align exactly with each day of the calendar. Considering the available space on the left, this would mean no Y axis/axis legend (for volume units) if I am not mistaken but let me know if you see another option. Therefore, the bars would need to be interactible : on press, it would display a small dialog showing the volume number.
Please create a detailed plan of how you will achieve and implement this step. Don't hesitate to let me know if you think of any meaningful and realistic improvements I might have overlooked.
Before you create the plan, please ask any and all questions you have in order to provide the most robust solution to handle edge cases and/or additional context that you might need to feel confident in proceeding with the implementation. When you do use clarifying questions, please do not use bullet points but rather letters within each numbered question if number requires bullet points. Before you ask me questions, please already have a look at all the existing files you would need, as well as previously implemented steps, to already have the context, use existing systems, ensure coherence and in case you already find the answer to your questions. Suggest for each question your recommended solution. Keep in mind that I want to have the best suited solution for my project while being in line with industry standards and app development best practices as much as possible. Please follow Firebase and Flutter best practices and use built-in solutions whenever possible instead of more complex custom/hacky workarounds. Also, keep in mind the CRUD rules file (.cursor/rules/firebase_CRUDrules.md) to make sure to keep firebase costs to a minimum. Regarding database, I don't need to worry about backward compatibility since I will regularily delete the database anyway for testing.

1. a) No Y-axis at all - Just bars and the goal line, rely entirely on tap interaction to see numbers (cleanest, aligns best with calendar)
2. Option (a) tap + option (c) tooltip style. Show a
  compact tooltip directly above the bar showing "85ml / 100ml (85%)" -
  quick, contextual, doesn't block the view. This matches mobile app best practices for chart interactions. I like this idea but above the bar will be the calendar, so it would overlap with the calendar ?
3. c) Different for past vs future - No bar for future dates, ghost bar for past dates with zero (shows missed opportunities)
4. - Colors: Single primary teal color with varying opacity (0-50% = light
  teal 40% opacity, 50-100% = medium teal 70% opacity, >100% = full teal
  100% opacity) - keeps it simple and focused on volume
  - Corners: Rounded top corners (4px radius) - friendlier and matches your
  app's design language
  - Goal line: Dashed horizontal line in amber (matches "today" color,
  clearly distinguishable)
  - Width: 80% of column width - easy to tap, leaves small visual margin
5. b) Week view only - Hidden in month view to avoid cramped visualization
6. Option (a) with 12px padding - tight enough to feel
  integrated, enough breathing room to be distinct.
7. Actually, I would like to have a loading spinner in the middle of the chart. And once we have the date, it would be beautiful to have a very short animation of the bars "rising" to their final level. Would this be possible ? Do we need/should use another existing flutter package for that ?
8. b) Show tiny bar - 2-3px tall bar in coral/warning color
9. Option (b) daily total goal - most intuitive for users
  ("Did I hit my goal FOR THIS DAY?"). This aligns with the fluidDailyGoalMl
   field already in your DailySummary model.
10. b) Taller for visibility - 100-120px. I am not sure what this represent, but I would like this chart to fill about 1/4 of the total screen.
Please let me know if this makes sense or contradict itself, the prd (.cursor/reference/prd.md), the CRUD rules or existing code. Coherence and app development/Flutter best practices are extremely important. Please confirm that this follow industry standards, and if not explain why. Let me know if you need any more clarifications to feel confident in proceeding with the implementation. Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself. After implementation, check for linting issues (flutter analyze) and, if you found any, fix them (including the non critical ones). I will test only once we fixed the linting issues. We will create the plan in /Users/marc-antoinemalacquis/Development/projects/hydracat/~PLANNING/progessBar_fluid.md


- Would it be possible to have a smart position but rather left/right. So basically for monday, tuesday, wednesday, thursday, the info box would be to the right of the bar overlapping the right side of the chart. For friday, saturday, sunday, the info box would be to the left of the bar overlapping the left side of the chart. This would be even better if the info box only shows while the user is tapping on the bar and disappear once the user remove his finger from the bar (very reactive for great UX). Would this be realistic ?
The small info box would show on line 1 "85ml / 100ml" and line 2 "(85%)" to keep it compact. No need for "Mon:" since it will be already on the X axis.
- Let's go with 200px for the char height
- perfect rising Animation
