import { useParams } from 'next/navigation';
import { useState, useEffect } from 'react';

// Simple translation hook that doesn't require next-intl config
export function useTranslations(namespace: string) {
  const params = useParams();
  const locale = params?.locale as string || 'en';
  const [messages, setMessages] = useState<Record<string, any>>({});

  useEffect(() => {
    // Load messages for the current locale
    const loadMessages = async () => {
      try {
        const messagesModule = await import(`../messages/${locale}.json`);
        setMessages(messagesModule.default || {});
      } catch (error) {
        console.warn(`Could not load messages for locale: ${locale}`);
        setMessages({});
      }
    };

    loadMessages();
  }, [locale]);

  return (key: string) => {
    try {
      // Navigate through nested object using dot notation
      const keys = key.split('.');
      let value = messages;
      
      for (const k of keys) {
        if (value && typeof value === 'object' && k in value) {
          value = value[k];
        } else {
          return key; // Return key as fallback
        }
      }
      
      return typeof value === 'string' ? value : key;
    } catch (error) {
      return key;
    }
  };
}

export function useLocale() {
  const params = useParams();
  return params?.locale as string || 'en';
}