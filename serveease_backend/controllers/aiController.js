import aiService from '../services/aiService.js';

// Handle AI chat conversation
const chatWithAI = async (req, res) => {
  try {
    const { message, conversationHistory = [] } = req.body;
    const userId = req.user?.id;

    if (!message || message.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Message is required'
      });
    }

    // Get AI response
    const result = await aiService.generateResponse(message, userId, conversationHistory);

    // Add user message to conversation history
    const updatedHistory = [
      ...conversationHistory,
      { role: 'user', content: message },
      { role: 'assistant', content: result.response }
    ];

    res.json({
      success: true,
      response: result.response,
      actions: result.actions,
      conversationHistory: updatedHistory,
      context: result.context
    });

  } catch (error) {
    console.error('AI Chat Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to process AI request',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Get AI-powered service recommendations
const getServiceRecommendations = async (req, res) => {
  try {
    const { query, category } = req.query;
    const userId = req.user?.id;

    let recommendations = [];

    if (query) {
      // Use AI to analyze query and recommend services
      const services = await aiService.getServiceRecommendations(query, category);
      recommendations = services;
    } else {
      // Get general popular services
      recommendations = await aiService.getServiceRecommendations(null, category);
    }

    res.json({
      success: true,
      recommendations: recommendations.map(service => ({
        id: service.id,
        title: service.title,
        description: service.description,
        price: parseFloat(service.price),
        durationHours: service.duration_hours,
        category: service.category_name,
        provider: service.business_name,
        location: service.location
      }))
    });

  } catch (error) {
    console.error('Service Recommendations Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get recommendations'
    });
  }
};

// Get AI-powered provider recommendations
const getProviderRecommendations = async (req, res) => {
  try {
    const { serviceType } = req.query;

    const providers = await aiService.getProviderRecommendations(serviceType);

    res.json({
      success: true,
      recommendations: providers.map(provider => ({
        id: provider.id,
        businessName: provider.business_name,
        description: provider.description,
        category: provider.category,
        location: provider.location,
        providerType: provider.provider_type,
        isApproved: provider.is_approved,
        serviceCount: parseInt(provider.service_count),
        averageRating: provider.avg_rating ? parseFloat(provider.avg_rating) : null
      }))
    });

  } catch (error) {
    console.error('Provider Recommendations Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get provider recommendations'
    });
  }
};

// Analyze user query and suggest actions
const analyzeQuery = async (req, res) => {
  try {
    const { query } = req.body;
    const userId = req.user?.id;

    if (!query || query.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Query is required'
      });
    }

    // Get AI analysis
    const result = await aiService.generateResponse(query, userId, []);

    // Extract intent and suggestions
    const intent = analyzeIntent(query);
    const suggestions = generateSuggestions(query, result.actions);

    res.json({
      success: true,
      intent: intent,
      suggestions: suggestions,
      aiResponse: result.response,
      actions: result.actions
    });

  } catch (error) {
    console.error('Query Analysis Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to analyze query'
    });
  }
};

// Get platform statistics and insights
const getPlatformInsights = async (req, res) => {
  try {
    const contextInfo = await aiService.getContextualInfo(req.user?.id);

    // Generate AI-powered insights
    const insights = await generateInsights(contextInfo);

    res.json({
      success: true,
      insights: insights,
      stats: contextInfo.stats,
      categories: contextInfo.categories
    });

  } catch (error) {
    console.error('Platform Insights Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get platform insights'
    });
  }
};

// Helper function to analyze user intent
function analyzeIntent(query) {
  const lowerQuery = query.toLowerCase();

  if (lowerQuery.includes('book') || lowerQuery.includes('schedule') || lowerQuery.includes('hire')) {
    return 'booking';
  } else if (lowerQuery.includes('find') || lowerQuery.includes('search') || lowerQuery.includes('looking')) {
    return 'search';
  } else if (lowerQuery.includes('help') || lowerQuery.includes('how') || lowerQuery.includes('what')) {
    return 'help';
  } else if (lowerQuery.includes('provider') || lowerQuery.includes('business') || lowerQuery.includes('register')) {
    return 'provider_setup';
  } else if (lowerQuery.includes('profile') || lowerQuery.includes('account') || lowerQuery.includes('settings')) {
    return 'account_management';
  } else {
    return 'general';
  }
}

// Generate contextual suggestions
function generateSuggestions(query, actions) {
  const suggestions = [];

  // Add action-based suggestions
  actions.forEach(action => {
    suggestions.push({
      type: 'action',
      title: action.description,
      target: action.target
    });
  });

  // Add query-based suggestions
  const lowerQuery = query.toLowerCase();

  if (lowerQuery.includes('clean')) {
    suggestions.push({
      type: 'category',
      title: 'Browse Cleaning Services',
      target: 'category',
      params: { categoryId: 'cleaning' }
    });
  }

  if (lowerQuery.includes('repair') || lowerQuery.includes('fix')) {
    suggestions.push({
      type: 'category',
      title: 'Browse Home Repair Services',
      target: 'category',
      params: { categoryId: 'home_repair' }
    });
  }

  if (lowerQuery.includes('computer') || lowerQuery.includes('tech')) {
    suggestions.push({
      type: 'category',
      title: 'Browse IT Support Services',
      target: 'category',
      params: { categoryId: 'it_support' }
    });
  }

  // Add general helpful suggestions
  if (suggestions.length < 3) {
    suggestions.push({
      type: 'help',
      title: 'View All Service Categories',
      target: 'categories'
    });

    suggestions.push({
      type: 'help',
      title: 'How to Book a Service',
      target: 'faq',
      params: { topic: 'booking' }
    });
  }

  return suggestions.slice(0, 5); // Limit to 5 suggestions
}

// Generate platform insights
async function generateInsights(contextInfo) {
  const insights = [];

  try {
    const stats = contextInfo.stats;

    insights.push({
      type: 'statistic',
      title: 'Platform Growth',
      description: `ServeEase has ${stats.total_users} registered users and ${stats.active_providers} approved providers.`,
      icon: 'trending_up'
    });

    insights.push({
      type: 'service',
      title: 'Popular Categories',
      description: `Most requested services are in ${contextInfo.categories.slice(0, 3).map(c => c.name).join(', ')}.`,
      icon: 'category'
    });

    if (stats.total_requests > 0) {
      insights.push({
        type: 'engagement',
        title: 'Active Community',
        description: `${stats.total_requests} service requests have been made on the platform.`,
        icon: 'people'
      });
    }

    insights.push({
      type: 'tip',
      title: 'Get Started',
      description: 'Browse services by category or search for specific needs to find the perfect provider.',
      icon: 'lightbulb'
    });

  } catch (error) {
    console.error('Error generating insights:', error);
  }

  return insights;
}

export {
  chatWithAI,
  getServiceRecommendations,
  getProviderRecommendations,
  analyzeQuery,
  getPlatformInsights
};
