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


I would like to implement an inventory tracking feature where the user will be able to track how much fluid is left (mL) in their inventory based on the fluid logged during each fluid therapy session. This will be a premium feature.
Let's add an "Inventory" card in the list in the Profile screen. 
Inventory Screen : Large horizontal progress bar (0–100%) showing the total mL left since the last inventory refill
Estimate how many fluid sessions left with this current inventory and the estimated end date (day when there will not be enough fluid left to achieve the day's goal) based on schedule.
Display last refill date.
We will need to have a way for the user to edit the volume left value manually in case there was a leak during the session for example (so the volume isn't logged in the fluid session but should be removed from the inventory). I am not sure how other apps handle this, maybe the user can tap on the number to open a textedit to change it.
Let's add a "+ Refill" button (in the app bar) : opens a bottom sheet (app style) to input the fluid bags/bottles added to the inventory (500mL, 1000mL, or custom input) and how many. Calculate from this and display live in the popup the preview of the new total volume like "New inventory: 4537mL" (which will become the new 100%). We also need on the refill popup to let the user choose something like "Reminder for left sessions" with a slider (from 1 to 20 sessions left, default to 10 sessions left).
Then the user can press "Save" button (top right corner of popup, similar to other popups throughout the app).
Please create a detailed plan of how you will achieve and implement this step. Don't hesitate to let me know if you think of any meaningful and realistic improvements I might have overlooked.
Before you create the plan, please ask any and all questions you have in order to provide the most robust solution to handle edge cases and/or additional context that you might need to feel confident in proceeding with the implementation. When you do use clarifying questions, please do not use bullet points but rather letters within each numbered question if number requires bullet points. Before you ask me questions, please already have a look at all the existing files you would need, as well as previously implemented steps, to already have the context, use existing systems, ensure coherence and in case you already find the answer to your questions. Suggest for each question your recommended solution. Keep in mind that I want to have the best suited solution for my project while being in line with industry standards and app development best practices as much as possible. Please follow Firebase and Flutter best practices and use built-in solutions whenever possible instead of more complex custom/hacky workarounds. Also, keep in mind the CRUD rules file (.cursor/rules/firebase_CRUDrules.md) to make sure to keep firebase costs to a minimum. Regarding database, I don't need to worry about backward compatibility since I will regularily delete the database anyway for testing. We will write the plan in /Users/marc-antoinemalacquis/Development/projects/hydracat/~PLANNING/inventory_tracking.md.


1. yes, Shared inventory per user (matches schema), with
  estimates based on total daily fluid needs across all pets with active fluid
  schedules. This reflects real-world usage where pet owners typically buy
  fluid in bulk and use it for all their pets.
2. Automatic deduction (option a) for simplicity and user
  experience. Most sessions will use inventory, and users can use the manual
  adjustment feature if they used external supply or had waste. This minimizes
  friction during the logging flow.
3. Be a simple tap-to-edit on the current volume number (opens text input dialog)
4. we need to use only the current scheduled volume (no average). Please create the formula.
- Store threshold as "sessions left" (simpler for users to understand)
- Fire notification only once when threshold is crossed
- For multiple pets: sum their daily goals
5. Allow logging but show a prominent warning message. Logging needs to be independant from inventory. The inventory UI will stay at 0mL (0%).
6. Option b (optional activation). Don't add complexity to
   onboarding. Users discover the feature from the Profile screen, tap
  "Inventory" card, see empty state with explanation, and tap "+ Refill" to start tracking. This respects the progressive disclosure principle.
7. - Default to additive: currentRemainingVolume + refillAmount (option a)
  - But include a toggle/checkbox: "Reset inventory (ignore current amount)"
  for users who want to correct inaccurate tracking
  - Always update thresholdVolume based on the slider value in the refill
  popup, so users can adjust their reminder preference at refill time
8. - Always adjust inventory retroactively (option a) regardless of session age,
   but only for sessions logged after inventory tracking was first enabled
  (track activation date)
  - Add a flag inventoryTrackingEnabledAt to the inventory document
  - Session deletes: add volume back to inventory
  - Session edits: apply delta (newVolume - oldVolume)
  - Show a notification snackbar: "Inventory updated: +150mL restored"
9. Add:
  - lastRefillDate: Timestamp (required for UI display)
  - refillCount: number (simple counter, incremented on each refill)
  - inventoryEnabledAt: Timestamp (tracks when feature was activated)
  - refills subcollection for premium users wanting detailed history
Let's add the refills subcollection, this would be a nice improvement. What schema would it need to have ?
10. For now, let's not take into consideration the fact that it is a premium feature
Please look at all the relevant code and let me know what you think of those responses. Please let me know if this makes sense or contradict itself, the CRUD rules (.cursor/rules/firebase_CRUDrules.md) or existing code. Coherence and app development/Flutter best practices are extremely important. Please confirm if this follow best practices, and if not explain why. Once I have read and confirm your analysis, I will ask you to provide another set of questions to clarify, improve and make adjustement. Then when we are both confident about the implementation, we will create the plan.



1. Perfect, yes this approach works for me
2. Yes but I don't know if this matters but by far (>90%) of users will only have one pet (primary pet) so I don't know if some optimisation would even be worth doing here. It might not even be worth it, but please verify.
Also, from your example, actually 800/117=6.8 so, it remains only 6 sessions since we won't have enough fluid to do a 7th. We need to think practical and real life.
3. yes, conservative rounding
4. Yes, this logic makes sense. But it would make more sense for the user to be able to see (inventory screen) the negative values like "You have logged XmL while the inventory is empty". What do you think ?
5. Perfect for the refills ! But I don't want to track the manual adjustments (I don't think it brings much value)
6. Yes, except I don't want to track the manual adjustments (I don't think it brings much value)
7. Yes, let's do the latter for separation of concerns:
  // In LoggingProvider after successful fluid logging
  await ref.read(inventoryServiceProvider).checkThresholdAndNotify();
8. The warning will be on the home screen (in a separate inventory summary card), but we will implement it later. It will be When remainingVolume < thresholdVolume (tied to notification
  threshold) for consistency 
9. Yes, we need to add session deletion first. We will need to add it to the focused day popup (where there is the list of sessions for each day) with a bin icon next to the edit icon with a following confirmation popup.
10. Option A: Show "Unable to estimate (no active schedules)
Please let me know if this makes sense or contradict itself, the CRUD rules (.cursor/rules/firebase_CRUDrules.md) or existing code. Coherence and app development/Flutter best practices are extremely important. Please confirm that this follow industry standards, and if not explain why. Let me know if you need any more clarifications to feel confident in proceeding with the implementation. Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself. After implementation, check for linting issues (flutter analyze) and, if you found any, fix them (including the non critical ones). I will test only once we fixed the linting issues. We will write the detailed step-by-step plan in /Users/marc-antoinemalacquis/Development/projects/hydracat/~PLANNING/inventory_tracking.md (follow the example of /Users/marc-antoinemalacquis/Development/projects/hydracat/~PLANNING/DONE/dashboard_plan.md)