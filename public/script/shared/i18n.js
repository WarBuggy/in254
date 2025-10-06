window.addEventListener('DOMContentLoaded', () => {
    (function setupTranslation() {
        const DEFAULT_LANGUAGE = 'en';

        let currentLanguage;
        let currentMessages;

        function initLanguage() {
            const langCode = localStorage.getItem(Shared.STORAGE_KEY_LIST.LANGUAGE);
            if (langCode && window.translatableTexts[langCode]) {
                currentLanguage = langCode;
            } else {
                console.warn(`No translation found for ${langCode}. Fall back to en-English.`);
                currentLanguage = DEFAULT_LANGUAGE;
                localStorage.setItem(Shared.STORAGE_KEY_LIST.LANGUAGE, DEFAULT_LANGUAGE);
            }
            currentMessages = window.translatableTexts[currentLanguage] || {};
        };

        function formatByOrder(template, values = []) {
            let index = 0;
            return template.replace(/\{[^}]+\}/g, () => values[index++] ?? 'not_given');
        };

        // Create proxy for taggedString
        window.taggedString = new Proxy({}, {
            get(_, prop) {
                const template = currentMessages[prop] ?? `{${prop}}`;
                return (...values) => formatByOrder(template, values);
            }
        });

        initLanguage();
    })();
});

// TODO: Expose language controls
//window.setLanguage = setLanguage;
//window.getCurrentLanguage = () => currentLanguage;
// function getCurrentLanguage() {
//     let lang = localStorage.getItem(Shared.STORAGE_KEY_LIST.LANGUAGE);
//     if (!lang) {
//         lang = 'en';
//         localStorage.setItem(Shared.STORAGE_KEY_LIST.LANGUAGE, lang);
//     }
//     return lang;
// };
// Initialize once

// CHAT GPT prompt to remind using taggedString
/*
Remember this important point:
Whenever generating or updating code for classes that may throw errors or use textual messages, always use the taggedString system instead of raw strings. Specifically:
Error messages or strings must be referenced as function calls in the form
```taggedString.classNameStringDescription(arg1, arg2)```
where className is the name of the class, StringDescription describes the message, and arg1, arg2 are optional template arguments.

The taggedString entry itself should contain the template with placeholders, e.g.:
```classNameStringDescription: "Actual string content {arg1} {arg2}"```
If the message requires no arguments, always include the parentheses:
```taggedString.classNameStringDescription()```
Never reference the function without parentheses.
*/


/*
Remember this important point:
Write all methods in such a way that input is always a single object named input. Destructure the needed properties from input at the start of the method. The method must always return an object containing all output values. Do not take multiple parameters or return a single value. Use the structure:

methodName(input) {
    const { a,b,c, } = input;
    // method logic
    return { x,y,z, };
}
*/