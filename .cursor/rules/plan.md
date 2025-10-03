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


1. a) yes, optional in case the user doesn't know it
b) yes, allow both. must be positive only for validation.
c) since it's optional, they can just not fill it if it doesn't apply.
2. a) yes, include all those units
b) no other units for now
c) yes, have an "other" option just in case
3. a) same line as the name (e.g., "Furosemide 2.5 mg")
b) no specific convention yet, let's not think about the professional vet report yet
4. a) exactly, no backward compatibility needed
b) "not specified"
5. a) above the existing unit selector
b) standard Flutter dropdown
c) "e.g., 2.5 mg, 5 mg/mL" is perfect
6. a) create a new medication entry
b) no uniqueness validation, the
  user can have two entries for "Furosemide" with different strengths like "2.5 mg" and "5 mg"?
Please let me know if this makes sense or contradict itself, the prd, the CRUD rules or existing code. Coherence is extremely important. Let's me know if you need any more clarifications to feel confident in proceeding with the implementation. Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself.



