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

Just like we created for ckd profile and the persona-based fluid schedule to be able to see and edit the informations provided during the onboarding, I want to create now a persona-based "*cat's name*'s medication schedule" card (only appears if medication only or medication & fluid persona was selected during onboarding) in the profile screen. By pressing it, it will lead to a new medication screen that contains an editable list of the medications (set up during onboarding) similar to the medication summary from onboarding where the user will be able to press any of the medication card to be able to edit those medication specific settings.

1. yes continue with this approach as individual schedule if you think this is the most cost-effective way for the app.
2. they should be able to edit all medication proprieties similar to the onboarding flow. It would actually make sense to reuse here the exact same UI of the onboarding with the card summary that they can press to edit (exactly as it is in the onboarding) so we can optimise and reuse code.
3. Exact same layout as onboarding.
4. Yes, please add the missing medicationUnit field to the Schedule model. Although the medicationUnit is currently correctly stored in firestore.
5. Use the exact same layout as the other screens for coherence
6. Yes, please extend the existing ProfileProvider to
  handle medication schedules similar to how it handles fluid schedules if you believe this is what makes the most sense
7. yes, follow the same error handling
8. yes, the dosage should be stored as a
  string (like "1/2", "2.5") to preserve the original format from onboarding.
Please let me know if this makes sense or contradict itself, the prd, the CRUD rules or existing code. Coherence is extremely important. Let's me know if you need any more clarifications to feel confident in proceeding with the implementation. Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself.

