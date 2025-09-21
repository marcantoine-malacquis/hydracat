---
description: Ask clarifying questions
    - "**/*"

alwaysApply: false
---

After analysing the situation and looking at the relevant code, please ultrathink to come up with the most appropriate plan to achieve this. Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself.

Please ultrathink to come up with the most appropriate plan to achieve this. After analysing the situation and looking at the relevant code, please ask me any question you would need to feel confident about solving the issues. Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself.

Please create a detailed plan of how you will achieve and implement this step.
Before you create the plan, please ask any and all questions you have in order to provide the most robust solution to handle edge cases and/or additional context that you might need to feel confident in proceeding with the implementation. When you do use clarifying questions, please do not use bullet points but rather letters within each numbered question if number requires bullet points. Before you ask me questions, please already have a look at all the existing files you would need to already have the context, use existing systems, ensure coherence and in case you already find the answer to your questions. Keep in mind that I want to have the best suited solution for my project while being in line with industry standards as much as possible. Also, keep in mind the CRUD rules file (.cursor/rules/firebase_CRUDrules.md) to make sure to keep firebase costs to a minimum.

Please let me know if this makes sense or contradict itself, the prd, the CRUD rules or existing code. Coherence is extremely important. Let's me know if you need any more clarifications to feel confident in proceeding with the implementation. Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself.

Please update and add only the important informations to remember about what we implemented in this step for future reference in 

Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself.


1. a) from the completed pet profile (CatProfile.medicalInfo)
b) show empty state for each element. for example "CKD IRIS stage: no information" or something like that. For each of this items, there will be on the right an industry standard small "pen" button to edit each information manually whithout going though the onboarding. This will be useful for example, if they didn't provide just one information, they will still be able to see all the other ones and fill in manually the last one whenever they want/can.
c) Rely entirely on the existing primaryPetProvider cache. They thing is that we will need to update the stored data when they press a "Save" button at the bottom of the screen that appears only if they edited at least one information. would this be the industry standard and best way to do this ?
2. a) nested in the profile route
b) only through the profile screen navigation
c) standard back button behavior, no navigation bar, a "Save" button at the bottom of the screen that appears only if they edited at least one information.
3. a) let's try an elegant simplistic Material 3 ListTile that suits my UI guidelines
b) let's use the same layout structure as profile_screen.dart
c) in a separate section with other profile-related items I plan to add later
4. a) show empty state for each element. for example "CKD IRIS stage: no information" or something like that. Please do something similar to industry standards.
b) empty/missing values be displayed as "no information" or something like that, that is industry standard
c) no need for visual indicators for data freshness for now
5. a) show "no information" or something like that for every element
b) no need for any validation or warnings if medical data seems outdated. I don't need that
c) wrap to multiple lines. thanks this is a very good question I didn't think about.
6. a) yes,create a reusable component architecture. for more context, the other ones will be for example "My Schedule" to modify the planned schedule but we will implement them later on.
b) it should be editable already now with an industry standard small "pen" button to edit each information manually.
c) the static cached approach is sufficient now
Please let me know if this makes sense or contradict itself, the prd, the CRUD rules or existing code. Coherence is extremely important. Let's me know if you need any more clarifications to feel confident in proceeding with the implementation. 

1. yes, same validation logic as onboarding 
2. show an error message and keep the local edits
3. ProfileSectionItem
4. Yes, let's use the exact same edit types as onboarding so we also ensure the data is in a consistent style 








