import { createSignal } from 'solid-js';
import { translations } from './translations.js';

const [currentLanguage, setCurrentLanguage] = createSignal('en');

export function useTranslation() {
  const t = (key) => {
    return translations[currentLanguage()]?.[key] || key;
  };

  const setLanguage = (lang) => {
    setCurrentLanguage(lang);
    // Set document direction for RTL languages
    if (lang === 'ar') {
      document.documentElement.dir = 'rtl';
    } else {
      document.documentElement.dir = 'ltr';
    }
  };

  return { t, setLanguage, currentLanguage };
}