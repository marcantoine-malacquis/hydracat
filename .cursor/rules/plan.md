---
description: Ask clarifying questions
    - "**/*"

alwaysApply: false
---

After analysing the situation and looking at the relevant code, please ultrathink to come up with the most appropriate plan to fix this issue. Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself.

Please ultrathink to come up with the most appropriate plan to achieve this. After analysing the situation and looking at the relevant code, please ask me any question you would need to feel confident about solving the issues. Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself.

Please create a detailed plan of how you will achieve and implement this step.
Before you create the plan, please ask any and all questions you have in order to provide the most robust solution to handle edge cases and/or additional context that you might need to feel confident in proceeding with the implementation. When you do use clarifying questions, please do not use bullet points but rather letters within each numbered question if number requires bullet points. Before you ask me questions, please already have a look at all the existing files you would need to already have the context, use existing systems, ensure coherence and in case you already find the answer to your questions. Keep in mind that I want to have the best suited solution for my project while being in line with industry standards as much as possible. Please follow Firebase and Flutter best practices and use built-in solutions whenever possible instead of more complex custom solutions. Also, keep in mind the CRUD rules file (.cursor/rules/firebase_CRUDrules.md) to make sure to keep firebase costs to a minimum. Regarding database, I don't need to worry about backward compatibility since I will regularily delete the database anyway for testing. After implementation, don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself.

Please let me know if this makes sense or contradict itself, the prd, the CRUD rules or existing code. Coherence is extremely important. Let's me know if you need any more clarifications to feel confident in proceeding with the implementation. Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself.

Please update and add only the important informations to remember about what we implemented in this step for future reference in 

Please follow Firebase and Flutter best practices and use built-in solutions whenever possible instead of more complex custom solutions.

Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself.

Here is a conversation i had about those questions. Please review it and let me know what you agree with and what you would disagree with.


Let's fix the issue ... as documented in @onboarding_code_review_report.md. Please have a look at the relevant files and create the best plan to fix the issue. 

The next feature I am now going to work on for my app is the treatment logging system.
Please create a very detailed implementation plan in @~PLANNING/logging_plan.md similar to what I did for @~PLANNING/DONE/onboarding_profile_plan.md and
@~PLANNING/DONE/auth_implementation_plan.md . So the plan is to have at the end of this logging implementation plan: 
the user can press on the logging FAB button in the navigation bar so the already existing logging screen pop-up with pre-filled data for the session and a large "Log" button at the bottom. The logging pop-up should have persona awareness (from onboarding selection): medication data for medication persona, fluid data for fluid persona. If the user has chosen the medication & fluid therapy persona during onboarding, a very small pop-up appear above the navigation bar first with buttons for "log medication" and "log fluid" so the user is redirected to the relevant pop-up. I want it to be really user friendly so no scrolling should be needed if possible. For those pop-up screens, the background behind the pop-up should be blurred so the user attention is focused on the pop-up. Only the navigation bar stays unblurred.
For ease of use, the user should also have the option to stay pressed longer on the FAB button when the day session went well and automatically log all data for the day. An elegant pop-up then appear above the navigation bar saying something like "today's session logged".
Before you create the plan, please ask any and all questions you have in order to provide the most robust solution to handle edge cases and/or additional context that you might need to feel confident in proceeding with the implementation. When you do use clarifying questions, please do not use bullet points but rather letters within each numbered question if number requires bullet points. Before you ask me questions, please already have a look at all the existing files you would need to already have the context, use existing systems, ensure coherence and in case you already find the answer to your questions. Keep in mind that I want to have the best suited solution for my project while being in line with industry standards as much as possible. Please follow Firebase and Flutter best practices and use built-in solutions whenever possible instead of more complex custom solutions. Also, keep in mind the CRUD rules file (.cursor/rules/firebase_CRUDrules.md) to make sure to keep firebase costs to a minimum. Regarding database, I don't need to worry about database backward compatibility since I will regularily delete the database anyway for testing.
Ideally, I would like the plan to have an approach that provides immediate visual feedback while building solid foundations to keep me engaged.


1. a) yes, exactly
b) yes, track which scheduled reminder time it relates to
c) batch-update it
2. a) yes, log all scheduled treatments for today at their default values (target volume/dosage from schedules). Only work if no sessions have been logged yet today.
b) use the scheduled reminder times from the user schedules
c) Log all of them individually, respecting their specific schedules and reminder times.
3. a) every time the FAB is pressed
b) yes, perfect order: Volume (required)
  - Injection site (optional from schedule)
  - Stress level (optional)
  - Notes (optional, should be a very small field that can expand only if the user press on it to write something)
c) strictly log actual administered amounts. so the user can compare and we can analyse versus the schedule plan
4. a) Warn and allow override (update existing session). The major advantage of the app is to be able to track differences between the plan and the real administered treatment. So for example if the plan is to administer 100mL/day: a user can log 80mL at one point and log 20mL another time. Or if the second fluid session didn't succeed, it can stay at 80mL and we will know that that day we missed 20mL.
b) just for volume. let's do 1-500mL.
5. a) write session and all summaries. Always batch session + 3 summary updates together
b) yes, absolutely cache today's treatment summary locally to avoid reads when checking if
  treatments are already logged
c) always single batch write
6. a) It should work completely offline with local storage and sync later
b) I think the last session logged chronologically wins but check if this is the industry standard or how it should be done
7. a) the logging models should mirror the onboarding treatment data structure
b) yes, for medication: the user should actually see the list of medication summary cards in the pop. when they press on one, there should be a feedback showing it is selected so they can select however many they want. then they can press the Log button in the popup. so they have flexible options, log one or multiple.
8. a) Yes, have a look around if you see components you can try to reuse for coherence. You can have a look also at the UI guidelines file.
b) yes, let's first try to match the onboarding UI style and I will see after if this is fine or if it will need to be modified.
c) I didn't know about backdropfilter but it might be the right solution if you think this could be implemented well and be elegant in my design.
Please let me know if this makes sense or contradict itself, the prd, the CRUD rules or existing code. Coherence is extremely important. Let's me know if you need any more clarifications to feel confident in proceeding with the implementation.

1. a) Linked to the 8:00 AM reminder (closest match)
b) then we should save the timestamp of that new logging, if this is possible and doesn't break coherence. let me know if you think another solution would be more optimised.
2. a) yes, as if the medications were done one by one but here that allow us to batch write quite easily
b) yes also fluid therapy. this is really a way for the user to very easily log the day as if everything went well with no deviation from the schedule. It's a all in one solution for ease of use when the user want extra fast logging.
3. a) one input for each selected medication
b) yes, that would be 3 separate session documents
4. a) what would be the industry-standard way of doing this ?
b) yes, update summaries
5. a) yes, based on the session's createdAt timestamp
b) Keep the session that was created last (based on createdAt)
6. A single-line text field that expands to multi-line when focused
7. Yes, perfect ! For medicationSessions:
  - dateTime, medicationName, dosageGiven, dosageScheduled, completed,
  administrationMethod, notes, scheduleId (to link to reminder time)?
  For fluidSessions:
  - dateTime, volumeGiven, stressLevel, injectionSite, notes, scheduleId (to link to
  reminder time).

We need to keep in mind that we will want those data to be able to analyse treatment adherence later on. for example, things like:
Medication Adherence Report (Last 90 days)
─────────────────────────────────────────
Amlodipine 2.5mg:     87% adherence (156/180 doses)
Benazepril 5mg:       92% adherence (83/90 doses)
Calcitriol 0.25mcg:   78% adherence (70/90 doses)
⚠️ Note: Calcitriol adherence below target

Please let me know if this makes sense or contradict itself, the prd, the CRUD rules or existing code. Coherence is extremely important. Let's me know if you need any more clarifications to feel confident in proceeding with the implementation.


