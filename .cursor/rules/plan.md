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
the user can press on the logging FAB button in the navigation bar so the already existing logging screen pop-up with pre-filled data for the session and a large "Log" button at the bottom. If the user has chosen the medication & fluid therapy persona, a very small pop-up appear above the navigation bar first with buttons for "log medication" and "log fluid" so the user is redirected to the relevant pop-up. I want it to be really user friendly so no scrolling should be needed if possible. For those pop-up screens, the background behind the pop-up should be blurred so the user attention is focused on the pop-up. Only the navigation bar stays unblurred.
For ease of use, the user should also have the option to stay pressed longer on the FAB button when the day session went well and automatically log all data for the day. An elegant pop-up then appear above the navigation bar saying something like "today's session logged".