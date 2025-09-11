---
description: Ask clarifying questions
    - "**/*"

alwaysApply: false
---

Please create a detailed plan of how you will achieve and implement this step.
Before you create the plan, please ask any and all questions you have in order to provide the most robust solution to handle edge cases and/or additional context that you might need to feel confident in proceeding with the implementation. When you do use clarifying questions, please do not use bullet points but rather letters within each numbered question if number requires bullet points. Before you ask me questions, please already have a look at all the existing files you would need to already have the context and in case you already find the answer to your questions. Keep in mind that I want to have the best suited solution for my project while being in line with industry standards as much as possible. Also, keep in mind the CRUD rules file to make sure to keep firebase costs to a minimum.

Please let me know if this makes sense or contradict itself, the prd or existing code. Let's me know if you need any more clarifications to feel confident in proceeding with the implementation.

Please add only the important informations to remember about what we implemented in this step for future reference in 

1. validation on-submit only. I prefer inline error messages under each field.
2. there really isn't much conflict. a) yes we can check if there is already an existing pet for the same user and show a warning if this is the case. b) absolutely no global check because it is useless and would go against our CRUD rules to limit firebase costs c) There might already be a service to put an upper case for the first letter of names in string_extensions.dart , if there is no upper case it is still validated but changed automatically before it's registered in the database d) after submission
3. a) yes a toggle switch b) no automatic conversion c) 2 decimales maximum (example: 3,22 kg) but I think we already have set such limitations in a dedicated file, please have a look d) yes, store this prefered unit locally.
4. a) I actually would prefer if the user input the date of birth that will be calculated autmatically by the app into a proper age number including months .We already have some rules about that. please have a look at date_utils.dart file b) start at the minimum
c) date picker approach and proper age will be calculated from this date of birth
5. a) not automacally b)i want a proper "Save & Continue" button c) no, those data will be mandatory to be able to move on in the onboarding d)best suited way for my app and industry standard
6. a) yes, they should go be able to go back to persona screen. b) no, keep the pet data c) no need for a confirmation dialog if they navigate away with unsaved changes?
7. a) No, name, age, gender are mandatory but weight, breed are not. b) yes collect gender (toggle button) and breed (string) c) no placeholder/helper text
8. a) we already have set validation rules for that in cat_profile.dart, please find them b) yes, we already have set rules for that, please find them c) same, find the rules about that please in one of the files already existing
9. a) no b)no c)no
10. a) yes, use what would make the most sense for the clean project and in line with industry standards b) please have a look at the ui_guidelines file c)yes, errors should match existing patterns
