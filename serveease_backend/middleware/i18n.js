import i18n from 'i18n';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Configure i18n
i18n.configure({
  locales: ['en', 'am'],
  defaultLocale: 'en',
  directory: path.join(__dirname, '../locales'),
  objectNotation: true,
  updateFiles: false,
  syncFiles: false,
  api: {
    '__': 't',
    '__n': 'tn'
  }
});

// Middleware to detect and set locale
export const i18nMiddleware = (req, res, next) => {
  // Get locale from various sources
  let locale = 'en'; // default
  
  // 1. Check Accept-Language header
  const acceptLanguage = req.headers['accept-language'];
  if (acceptLanguage) {
    const languages = acceptLanguage.split(',').map(lang => lang.split(';')[0].trim());
    const supportedLanguage = languages.find(lang => ['en', 'am'].includes(lang));
    if (supportedLanguage) {
      locale = supportedLanguage;
    }
  }
  
  // 2. Check query parameter
  if (req.query.lang && ['en', 'am'].includes(req.query.lang)) {
    locale = req.query.lang;
  }
  
  // 3. Check custom header
  if (req.headers['x-locale'] && ['en', 'am'].includes(req.headers['x-locale'])) {
    locale = req.headers['x-locale'];
  }
  
  // 4. Check user preference from database (if user is authenticated)
  if (req.user && req.user.preferredLanguage && ['en', 'am'].includes(req.user.preferredLanguage)) {
    locale = req.user.preferredLanguage;
  }
  
  // Set locale for this request
  i18n.setLocale(req, locale);
  i18n.setLocale(res, locale);
  
  // Add locale to request object for easy access
  req.locale = locale;
  
  // Add translation functions to request object
  req.t = (key, ...args) => i18n.__(key, ...args);
  req.tn = (singular, plural, count, ...args) => i18n.__n(singular, plural, count, ...args);
  
  next();
};

// Helper function to get localized message
export const getLocalizedMessage = (req, key, ...args) => {
  return req.t ? req.t(key, ...args) : key;
};

// Helper function to format error response with localization
export const formatErrorResponse = (req, errorKey, statusCode = 500, additionalData = {}) => {
  return {
    success: false,
    message: getLocalizedMessage(req, errorKey),
    statusCode,
    locale: req.locale || 'en',
    ...additionalData
  };
};

// Helper function to format success response with localization
export const formatSuccessResponse = (req, messageKey, data = {}, statusCode = 200) => {
  return {
    success: true,
    message: getLocalizedMessage(req, messageKey),
    statusCode,
    locale: req.locale || 'en',
    ...data
  };
};

// Helper function to get localized category name
export const getLocalizedCategory = (req, category) => {
  return getLocalizedMessage(req, `categories.${category}`) || category;
};

// Helper function to get localized status name
export const getLocalizedStatus = (req, status) => {
  return getLocalizedMessage(req, `status.${status}`) || status;
};

// Helper function to get localized role name
export const getLocalizedRole = (req, role) => {
  return getLocalizedMessage(req, `roles.${role}`) || role;
};

// Email template localization helper
export const getLocalizedEmailTemplate = (locale, templateKey, data = {}) => {
  const currentLocale = i18n.getLocale();
  i18n.setLocale(locale);
  
  const template = {
    subject: i18n.__(`email.${templateKey}Subject`),
    // Add more template properties as needed
  };
  
  // Restore original locale
  i18n.setLocale(currentLocale);
  
  return template;
};

export default i18n;