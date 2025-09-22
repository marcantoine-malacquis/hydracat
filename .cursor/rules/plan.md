---
description: Ask clarifying questions
    - "**/*"

alwaysApply: false
---

After analysing the situation and looking at the relevant code, please ultrathink to come up with the most appropriate plan to fix this issue. Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself.

Please ultrathink to come up with the most appropriate plan to achieve this. After analysing the situation and looking at the relevant code, please ask me any question you would need to feel confident about solving the issues. Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself.

Please create a detailed plan of how you will achieve and implement this step.
Before you create the plan, please ask any and all questions you have in order to provide the most robust solution to handle edge cases and/or additional context that you might need to feel confident in proceeding with the implementation. When you do use clarifying questions, please do not use bullet points but rather letters within each numbered question if number requires bullet points. Before you ask me questions, please already have a look at all the existing files you would need to already have the context, use existing systems, ensure coherence and in case you already find the answer to your questions. Keep in mind that I want to have the best suited solution for my project while being in line with industry standards as much as possible. Also, keep in mind the CRUD rules file (.cursor/rules/firebase_CRUDrules.md) to make sure to keep firebase costs to a minimum.

Please let me know if this makes sense or contradict itself, the prd, the CRUD rules or existing code. Coherence is extremely important. Let's me know if you need any more clarifications to feel confident in proceeding with the implementation. Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself.

Please update and add only the important informations to remember about what we implemented in this step for future reference in 

Please follow Firebase and Flutter best practices and use built-in solutions whenever possible instead of more complex custom solutions.

Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself.


1. Please refer to the firestore schema (/Users/marc-antoinemalacquis/Development/projects/hydracat/.cursor/rules/firestore_schema.md). a) Indeed all the schedule informations should be stored inside a dedicated schedule subcollection as you can see in the schema. b) just as it is the case for the ckd profile, when pressing on the fluid schedule card in Profile, the user will be redirected to a new fluid schedule screen where each field will show the information inputed during onboarding (or show "no information" for each field that was not inputed). Each of this field, just like the ckd profile screen, will have a small industry standard pen icon to edit the associated information.
2. a) please refer to the firestore schema (.cursor/rules/firestore_schema.md) and let me know if something is unclear or contradict itself. There should be a dedicated schedule subcollection inside of pet collection if I am not mistaken. b) no
3. a) yes, follow the example of ckd profile
b) editing should happen on the same screen thanks to the small edit button (pen incon) exactly like the ckd profile screen
4. a) yes, right after the CKD profile card
b) yes, similar UI elements and design patterns for coherence which is very important
5. a) please tell me what would be the most appropriate, simple and industry-standard solution. b) follow a similar synchronisation pattern as the ckd profile information if this makes sense
6. a) If a user initially selects "medication only" but later changes to include fluid therapy, the fluid therapy card will now appear in the Profile screen. We will handle this specific case another time. I am not sure yet, but I think the user will be redirected to the onboarding screen to input the fluid schedule data when he will include fluid therapy. Don't worry about this for now.
b) for now, the only way to add
  fluid therapy data post-onboarding for users who initially chose "medication only" will be thanks to this new fluid schedule screen in Profile. Later on, as I said I might redirect the user to the onboarding fluid therapy screen but not for now so don't worry about that.
Please let me know if this makes sense or contradict itself, the prd, the CRUD rules or existing code. Coherence is extremely important. Let's me know if you need any more clarifications to feel confident in proceeding with the implementation.  


regarding the schedules subcollection, a) preferredLocation (FluidLocation enum)
and needleGauge (string) should be stored in the schedule document as well. b) for now, let's assume there will only be one single reminder time for fluids.
Perfect, let's Extend the existing ProfileProvider with schedule-specific
   methods as you recommended.
Regarding the Questions for Final Clarification:
1. let's assume there will only be one single reminder time for fluids for now. so let's Create one schedule document for the fluid therapy with additional fields for preferredLocation and needleGauge
2. There will be only one fluid schedule for the pet for now.
3. At the end of the onboarding like all the other data, there is a "Finish" button on the completion screen. Please make it so additionally it also save the schedule document as well as the rest of the information like the basic pet profile.
According to the CRUD rules, should those schedule informations be locally stored since they are not going to be changed very regularily ?