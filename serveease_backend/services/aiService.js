import OpenAI from 'openai';
import { query } from '../config/database.js';

// Initialize OpenAI client only if API key is provided
let openai = null;
if (process.env.OPENAI_API_KEY) {
  openai = new OpenAI({
    apiKey: process.env.OPENAI_API_KEY,
  });
}

class AIService {
  constructor() {
    this.model = process.env.AI_MODEL;
    this.systemPrompt = this.buildSystemPrompt();
  }

  buildSystemPrompt() {
    return `You are ServeEase AI Assistant, a helpful and knowledgeable AI assistant for the ServeEase platform.

ServeEase connects service providers with service seekers. The platform offers various services including:

**Service Categories:**
- Home Repair (plumbing, electrical, carpentry)
- Cleaning (house cleaning, office cleaning)
- Gardening (lawn care, landscaping)
- IT Support (computer repair, software installation)
- Tutoring (academic tutoring, educational support)
- Automotive (car repair, maintenance)
- Beauty & Wellness (hair styling, massage, spa)
- Pet Care (pet sitting, grooming, veterinary assistance)
- Moving & Delivery (moving services, delivery, transportation)
- Event Services (event planning, catering, photography)

**User Types:**
- Service Seekers: Users looking to find and book services
- Individual Providers: Single-person service providers who need to upload certificates
- Organization Providers: Companies that can manage employees and assign them to service requests
- Admins: Platform administrators who approve providers and manage the system

**Key Features:**
- Provider approval system with certificate verification for individuals
- Employee management for organizations
- Service request booking and tracking
- Rating and review system
- Secure authentication with email verification

**Your Role:**
- Help users navigate the platform
- Answer questions about services and providers
- Assist with booking services
- Provide recommendations based on user needs
- Explain platform features and policies
- Help troubleshoot common issues
- Guide users through the registration and booking process

**Guidelines:**
- Be friendly, helpful, and professional
- Provide accurate information about the platform
- Suggest specific actions when appropriate
- Ask clarifying questions when user requests are unclear
- Respect user privacy and data security
- Encourage positive interactions between seekers and providers

Always maintain context about ServeEase being a service marketplace platform.`;
  }

  async getContextualInfo(userId = null) {
    let contextInfo = {};

    try {
      // Get user info if available
      if (userId) {
        const userResult = await query(
          'SELECT id, name, email, role, email_verified FROM users WHERE id = $1',
          [userId]
        );

        if (userResult.rows.length > 0) {
          contextInfo.user = userResult.rows[0];
        }
      }

      // Get service categories
      const categoriesResult = await query(
        'SELECT name, description FROM service_categories ORDER BY name',
        []
      );
      contextInfo.categories = categoriesResult.rows;

      // Get popular services (recently created)
      const servicesResult = await query(
        `SELECT s.title, s.price, sc.name as category, pp.business_name
         FROM services s
         JOIN service_categories sc ON s.category_id = sc.id
         JOIN provider_profiles pp ON s.provider_id = pp.id
         WHERE s.is_active = true
         ORDER BY s.created_at DESC
         LIMIT 10`,
        []
      );
      contextInfo.popularServices = servicesResult.rows;

      // Get system statistics
      const statsResult = await query(`
        SELECT
          (SELECT COUNT(*) FROM users) as total_users,
          (SELECT COUNT(*) FROM provider_profiles WHERE is_approved = true) as active_providers,
          (SELECT COUNT(*) FROM services WHERE is_active = true) as active_services,
          (SELECT COUNT(*) FROM service_requests) as total_requests
      `);
      contextInfo.stats = statsResult.rows[0];

    } catch (error) {
      console.error('Error getting contextual info:', error);
    }

    return contextInfo;
  }

  async generateResponse(userMessage, userId = null, conversationHistory = []) {
    try {
      // Check if OpenAI is available
      if (!openai) {
        return {
          response: "AI features are currently unavailable. Please contact support for assistance with: " + userMessage,
          actions: [],
          context: {},
          error: "OpenAI API key not configured"
        };
      }

      const contextInfo = await this.getContextualInfo(userId);

      // Build context-aware prompt
      let contextPrompt = `\n\nCurrent Context:`;

      if (contextInfo.user) {
        contextPrompt += `\n- User: ${contextInfo.user.name} (${contextInfo.user.role})`;
        contextPrompt += `\n- Email verified: ${contextInfo.user.email_verified}`;
      }

      contextPrompt += `\n- Platform stats: ${contextInfo.stats.total_users} users, ${contextInfo.stats.active_providers} providers, ${contextInfo.stats.active_services} services`;

      if (contextInfo.categories.length > 0) {
        contextPrompt += `\n- Available categories: ${contextInfo.categories.map(c => c.name).join(', ')}`;
      }

      // Prepare messages for OpenAI
      const messages = [
        { role: 'system', content: this.systemPrompt + contextPrompt },
        ...conversationHistory.slice(-10), // Keep last 10 messages for context
        { role: 'user', content: userMessage }
      ];
      const completion = await openai.chat.completions.create({
        model: process.env.AI_MODEL,
        messages
      });

      const aiResponse = completion.choices[0].message.content;

      // Analyze response for actionable items
      const actions = this.analyzeResponseForActions(aiResponse, contextInfo);

      return {
        response: aiResponse,
        actions: actions,
        context: contextInfo
      };

    } catch (error) {
      console.error('AI Service Error:', error);
      return {
        response: "I'm sorry, I'm having trouble processing your request right now. Please try again later or contact our support team.",
        actions: [],
        error: error.message
      };
    }
  }

  analyzeResponseForActions(response, contextInfo) {
    const actions = [];
    const lowerResponse = response.toLowerCase();

    // Check for service booking intent
    if (lowerResponse.includes('book') || lowerResponse.includes('schedule') || lowerResponse.includes('request')) {
      actions.push({
        type: 'navigate',
        target: 'service_categories',
        description: 'Browse available services'
      });
    }

    // Check for profile setup intent
    if (
      lowerResponse.includes('provider') && 
      lowerResponse.includes('register' || 'setup')) {
      actions.push({
        type: 'navigate',
        target: 'provider_setup',
        description: 'Set up provider profile'
      });
    }

    // Check for service search intent
    if (lowerResponse.includes('find') || lowerResponse.includes('search') || lowerResponse.includes('looking for')) {
      actions.push({
        type: 'navigate',
        target: 'search',
        description: 'Search for services'
      });
    }

    // Check for account/profile related queries
    if (lowerResponse.includes('profile') || lowerResponse.includes('account')) {
      actions.push({
        type: 'navigate',
        target: 'profile',
        description: 'View your profile'
      });
    }

    return actions;
  }

async getServiceRecommendations(userQuery, category = null) {
  try {
    const sql = category
      ? `SELECT s.*, sc.name as category_name, pp.business_name, pp.location
         FROM services s
         JOIN service_categories sc ON s.category_id = sc.id
         JOIN provider_profiles pp ON s.provider_id = pp.id
         WHERE s.is_active = true AND sc.name ILIKE $1
         ORDER BY s.created_at DESC
         LIMIT 5`
      : `SELECT s.*, sc.name as category_name, pp.business_name, pp.location
         FROM services s
         JOIN service_categories sc ON s.category_id = sc.id
         JOIN provider_profiles pp ON s.provider_id = pp.id
         WHERE s.is_active = true
         ORDER BY s.created_at DESC
         LIMIT 10`;

    const params = category ? [`%${category}%`] : [];
    const result = await query(sql, params);   // FIXED

    return result.rows;
  } catch (error) {
    console.error('Error getting service recommendations:', error);
    return [];
  }
}

  async getProviderRecommendations(serviceType) {
    try {
      const result = await query(
        `SELECT pp.*, COUNT(s.id) as service_count, AVG(sr.provider_rating) as avg_rating
         FROM provider_profiles pp
         LEFT JOIN services s ON pp.id = s.provider_id AND s.is_active = true
         LEFT JOIN service_requests sr ON pp.id = sr.provider_id
         WHERE pp.is_approved = true
         GROUP BY pp.id
         ORDER BY avg_rating DESC NULLS LAST, service_count DESC
         LIMIT 5`,
        []
      );

      return result.rows;
    } catch (error) {
      console.error('Error getting provider recommendations:', error);
      return [];
    }
  }
}

export default new AIService();
