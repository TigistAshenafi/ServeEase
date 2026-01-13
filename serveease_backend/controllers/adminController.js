import { query } from '../config/database.js';

// Helper function to log activities
const logActivity = async (type, description, userId = null, adminId = null, severity = 'info', metadata = null) => {
  try {
    await query(
      `INSERT INTO activity_logs (type, description, user_id, admin_id, severity, metadata)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [type, description, userId, adminId, severity, metadata]
    );
  } catch (error) {
    console.error('Failed to log activity:', error);
    // Don't throw error to avoid breaking main functionality
  }
};

// Get all users with pagination and filters
export const getAllUsers = async (req, res) => {
  try {
    const { page = 1, limit = 10, role } = req.query;
    const offset = (page - 1) * limit;

    let whereClause = '';
    let params = [limit, offset];

    if (role && ['seeker', 'provider', 'admin'].includes(role)) {
      whereClause = 'WHERE role = $3';
      params.push(role);
    }

    const result = await query(
      `SELECT id, name, email, role, email_verified, is_active, suspended_at, suspension_reason, created_at, updated_at
       FROM users
       ${whereClause}
       ORDER BY created_at DESC
       LIMIT $1 OFFSET $2`,
      params
    );

    // Get total count
    const countResult = await query(
      `SELECT COUNT(*) as total FROM users ${whereClause}`,
      role ? [role] : []
    );

    const total = parseInt(countResult.rows[0].total);

    res.json({
      success: true,
      users: result.rows.map(user => ({
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        emailVerified: user.email_verified,
        isActive: user.is_active,
        suspendedAt: user.suspended_at,
        suspensionReason: user.suspension_reason,
        createdAt: user.created_at,
        updatedAt: user.updated_at
      })),
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });

  } catch (error) {
    console.error('Get all users error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Suspend user
export const suspendUser = async (req, res) => {
  try {
    const { userId } = req.params;
    const { reason } = req.body;
    const adminId = req.user.id; // From auth middleware

    // Check if user exists and is not an admin
    const userCheck = await query(
      'SELECT role, name, email FROM users WHERE id = $1',
      [userId]
    );

    if (userCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const user = userCheck.rows[0];

    if (user.role === 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Cannot suspend admin users'
      });
    }

    const result = await query(
      `UPDATE users
       SET is_active = false, suspended_at = NOW(), suspension_reason = $1, updated_at = NOW()
       WHERE id = $2
       RETURNING id, name, email, is_active, suspended_at, suspension_reason`,
      [reason, userId]
    );

    // Log the activity
    await logActivity(
      'user_suspension',
      `User ${user.name} (${user.email}) was suspended. Reason: ${reason || 'No reason provided'}`,
      userId,
      adminId,
      'warning',
      { reason, suspended_by: req.user.name }
    );

    res.json({
      success: true,
      message: 'User suspended successfully',
      user: result.rows[0]
    });

  } catch (error) {
    console.error('Suspend user error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Activate user
export const activateUser = async (req, res) => {
  try {
    const { userId } = req.params;
    const adminId = req.user.id;

    // Get user info first
    const userCheck = await query(
      'SELECT name, email FROM users WHERE id = $1',
      [userId]
    );

    if (userCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const user = userCheck.rows[0];

    const result = await query(
      `UPDATE users
       SET is_active = true, suspended_at = NULL, suspension_reason = NULL, updated_at = NOW()
       WHERE id = $1
       RETURNING id, name, email, is_active`,
      [userId]
    );

    // Log the activity
    await logActivity(
      'user_activation',
      `User ${user.name} (${user.email}) was reactivated`,
      userId,
      adminId,
      'success',
      { activated_by: req.user.name }
    );

    res.json({
      success: true,
      message: 'User activated successfully',
      user: result.rows[0]
    });

  } catch (error) {
    console.error('Activate user error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Delete user
export const deleteUser = async (req, res) => {
  try {
    const { userId } = req.params;

    // Check if user exists and is not an admin
    const userCheck = await query(
      'SELECT role FROM users WHERE id = $1',
      [userId]
    );

    if (userCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    if (userCheck.rows[0].role === 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Cannot delete admin users'
      });
    }

    await query('DELETE FROM users WHERE id = $1', [userId]);

    res.json({
      success: true,
      message: 'User deleted successfully'
    });

  } catch (error) {
    console.error('Delete user error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Get all services with pagination and filters
export const getAllServices = async (req, res) => {
  try {
    const { page = 1, limit = 10, status } = req.query;
    const offset = (page - 1) * limit;

    let whereClause = 'WHERE pp.status = \'approved\'';
    let params = [limit, offset];

    if (status === 'active') {
      whereClause = 'WHERE pp.status = \'approved\' AND s.is_active = true';
    } else if (status === 'inactive') {
      whereClause = 'WHERE pp.status = \'approved\' AND s.is_active = false';
    }

    const result = await query(
      `SELECT s.*, 
              pp.business_name, pp.user_id, pp.is_approved,
              u.name as provider_name, u.email as provider_email,
              sc.name as category_name
       FROM services s
       JOIN provider_profiles pp ON s.provider_id = pp.id
       JOIN users u ON pp.user_id = u.id
       LEFT JOIN service_categories sc ON s.category_id = sc.id
       ${whereClause}
       ORDER BY s.created_at DESC
       LIMIT $1 OFFSET $2`,
      params
    );

    // Get total count
    const countResult = await query(
      `SELECT COUNT(*) as total FROM services s 
       JOIN provider_profiles pp ON s.provider_id = pp.id 
       ${whereClause}`,
      []
    );

    const total = parseInt(countResult.rows[0].total);

    res.json({
      success: true,
      services: result.rows.map(service => ({
        id: service.id,
        providerId: service.provider_id,
        categoryId: service.category_id,
        title: service.title,
        description: service.description,
        isActive: service.is_active,
        provider: {
          businessName: service.business_name,
          user: {
            name: service.provider_name,
            email: service.provider_email
          }
        },
        category: {
          name: service.category_name
        },
        createdAt: service.created_at,
        updatedAt: service.updated_at
      })),
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });

  } catch (error) {
    console.error('Get all services error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Approve service
export const approveService = async (req, res) => {
  try {
    const { serviceId } = req.params;

    const result = await query(
      `UPDATE services
       SET is_active = true, updated_at = NOW()
       WHERE id = $1
       RETURNING *`,
      [serviceId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Service not found'
      });
    }

    res.json({
      success: true,
      message: 'Service approved successfully',
      service: result.rows[0]
    });

  } catch (error) {
    console.error('Approve service error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Reject service
export const rejectService = async (req, res) => {
  try {
    const { serviceId } = req.params;
    const { reason } = req.body;

    const result = await query(
      `UPDATE services
       SET is_active = false, updated_at = NOW()
       WHERE id = $1
       RETURNING *`,
      [serviceId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Service not found'
      });
    }

    // TODO: Send notification to provider about rejection with reason

    res.json({
      success: true,
      message: 'Service rejected',
      service: result.rows[0]
    });

  } catch (error) {
    console.error('Reject service error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Delete service
export const deleteService = async (req, res) => {
  try {
    const { serviceId } = req.params;

    await query('DELETE FROM services WHERE id = $1', [serviceId]);

    res.json({
      success: true,
      message: 'Service deleted successfully'
    });

  } catch (error) {
    console.error('Delete service error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Get dashboard statistics
export const getDashboardStats = async (req, res) => {
  try {
    // Get total users
    const usersResult = await query('SELECT COUNT(*) as total FROM users WHERE role != $1', ['admin']);
    const totalUsers = parseInt(usersResult.rows[0].total);

    // Get total providers
    const providersResult = await query('SELECT COUNT(*) as total FROM provider_profiles WHERE is_approved = true');
    const totalProviders = parseInt(providersResult.rows[0].total);

    // Get pending providers
    const pendingProvidersResult = await query('SELECT COUNT(*) as total FROM provider_profiles WHERE is_approved = false');
    const pendingProviders = parseInt(pendingProvidersResult.rows[0].total);

    // Get total services
    const servicesResult = await query('SELECT COUNT(*) as total FROM services');
    const totalServices = parseInt(servicesResult.rows[0].total);

    // Get active services
    const activeServicesResult = await query('SELECT COUNT(*) as total FROM services WHERE is_active = true');
    const activeServices = parseInt(activeServicesResult.rows[0].total);

    // Get total service requests
    const requestsResult = await query('SELECT COUNT(*) as total FROM service_requests');
    const totalRequests = parseInt(requestsResult.rows[0].total);

    // Get completed requests
    const completedRequestsResult = await query('SELECT COUNT(*) as total FROM service_requests WHERE status = $1', ['completed']);
    const completedRequests = parseInt(completedRequestsResult.rows[0].total);

    // Calculate revenue (mock data - implement based on your pricing model)
    const revenue = completedRequests * 50; // Example: $50 per completed request

    // Calculate growth percentages (comparing last 30 days to previous 30 days)
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    const sixtyDaysAgo = new Date(Date.now() - 60 * 24 * 60 * 60 * 1000);

    // User growth
    const recentUsersResult = await query(
      'SELECT COUNT(*) as total FROM users WHERE created_at >= $1 AND role != $2',
      [thirtyDaysAgo, 'admin']
    );
    const previousUsersResult = await query(
      'SELECT COUNT(*) as total FROM users WHERE created_at >= $1 AND created_at < $2 AND role != $3',
      [sixtyDaysAgo, thirtyDaysAgo, 'admin']
    );
    const recentUsers = parseInt(recentUsersResult.rows[0].total);
    const previousUsers = parseInt(previousUsersResult.rows[0].total);
    const userGrowth = previousUsers > 0 ? Math.round(((recentUsers - previousUsers) / previousUsers) * 100) : 0;

    // Provider growth
    const recentProvidersResult = await query(
      'SELECT COUNT(*) as total FROM provider_profiles WHERE created_at >= $1',
      [thirtyDaysAgo]
    );
    const previousProvidersResult = await query(
      'SELECT COUNT(*) as total FROM provider_profiles WHERE created_at >= $1 AND created_at < $2',
      [sixtyDaysAgo, thirtyDaysAgo]
    );
    const recentProviders = parseInt(recentProvidersResult.rows[0].total);
    const previousProviders = parseInt(previousProvidersResult.rows[0].total);
    const providerGrowth = previousProviders > 0 ? Math.round(((recentProviders - previousProviders) / previousProviders) * 100) : 0;

    // Service growth
    const recentServicesResult = await query(
      'SELECT COUNT(*) as total FROM services WHERE created_at >= $1',
      [thirtyDaysAgo]
    );
    const previousServicesResult = await query(
      'SELECT COUNT(*) as total FROM services WHERE created_at >= $1 AND created_at < $2',
      [sixtyDaysAgo, thirtyDaysAgo]
    );
    const recentServices = parseInt(recentServicesResult.rows[0].total);
    const previousServices = parseInt(previousServicesResult.rows[0].total);
    const serviceGrowth = previousServices > 0 ? Math.round(((recentServices - previousServices) / previousServices) * 100) : 0;

    // Request growth
    const recentRequestsResult = await query(
      'SELECT COUNT(*) as total FROM service_requests WHERE created_at >= $1',
      [thirtyDaysAgo]
    );
    const previousRequestsResult = await query(
      'SELECT COUNT(*) as total FROM service_requests WHERE created_at >= $1 AND created_at < $2',
      [sixtyDaysAgo, thirtyDaysAgo]
    );
    const recentRequests = parseInt(recentRequestsResult.rows[0].total);
    const previousRequests = parseInt(previousRequestsResult.rows[0].total);
    const requestGrowth = previousRequests > 0 ? Math.round(((recentRequests - previousRequests) / previousRequests) * 100) : 0;

    res.json({
      success: true,
      totalUsers,
      totalProviders,
      pendingProviders,
      totalServices,
      activeServices,
      totalRequests,
      completedRequests,
      revenue,
      totalRevenue: revenue, // Add totalRevenue for frontend consistency
      userGrowth,
      providerGrowth,
      serviceGrowth,
      requestGrowth
    });

  } catch (error) {
    console.error('Get dashboard stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Get activity logs
export const getActivityLogs = async (req, res) => {
  try {
    const { page = 1, limit = 20, type } = req.query;
    const offset = (page - 1) * limit;

    console.log('Fetching activity logs with params:', { page, limit, type, offset });

    let whereClause = '';
    let params = [limit, offset];

    if (type && ['user_registration', 'provider_approval', 'service_creation', 'request_completion', 'payment_processed', 'system_alert'].includes(type)) {
      whereClause = 'WHERE al.type = $3';
      params.push(type);
    }

    console.log('SQL Query params:', params);
    console.log('Where clause:', whereClause);

    const result = await query(
      `SELECT 
        al.id,
        al.type,
        al.description,
        al.severity,
        al.metadata,
        al.created_at,
        u.name as user_name,
        u.email as user_email,
        u.role as user_role,
        admin_u.name as admin_name
       FROM activity_logs al
       LEFT JOIN users u ON al.user_id = u.id
       LEFT JOIN users admin_u ON al.admin_id = admin_u.id
       ${whereClause}
       ORDER BY al.created_at DESC
       LIMIT $1 OFFSET $2`,
      params
    );

    console.log('Query result rows:', result.rows.length);

    // Get total count
    const countResult = await query(
      `SELECT COUNT(*) as total FROM activity_logs al ${whereClause}`,
      type ? [type] : []
    );

    const total = parseInt(countResult.rows[0].total);
    console.log('Total activity logs:', total);

    // Format logs for frontend
    const logs = result.rows.map(log => ({
      id: log.id,
      type: log.type,
      description: log.description,
      user: {
        name: log.user_name || 'System',
        email: log.user_email || 'system@serveease.com',
        role: log.user_role || 'system'
      },
      admin: log.admin_name ? {
        name: log.admin_name
      } : null,
      timestamp: log.created_at,
      severity: log.severity,
      metadata: log.metadata
    }));

    console.log('Formatted logs count:', logs.length);

    res.json({
      success: true,
      logs,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });

  } catch (error) {
    console.error('Get activity logs error:', error);
    console.error('Error stack:', error.stack);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Get user statistics
export const getUserStats = async (req, res) => {
  try {
    const { period = '30d' } = req.query;
    
    // Calculate date range based on period
    let daysAgo = 30;
    if (period === '7d') daysAgo = 7;
    else if (period === '90d') daysAgo = 90;
    else if (period === '1y') daysAgo = 365;
    
    const startDate = new Date(Date.now() - daysAgo * 24 * 60 * 60 * 1000);

    const result = await query(
      `SELECT 
        DATE(created_at) as date,
        COUNT(*) as count,
        role
       FROM users
       WHERE created_at >= $1 AND role != 'admin'
       GROUP BY DATE(created_at), role
       ORDER BY date ASC`,
      [startDate]
    );

    res.json({
      success: true,
      stats: result.rows
    });

  } catch (error) {
    console.error('Get user stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Get service statistics
export const getServiceStats = async (req, res) => {
  try {
    const { period = '30d' } = req.query;
    
    let daysAgo = 30;
    if (period === '7d') daysAgo = 7;
    else if (period === '90d') daysAgo = 90;
    else if (period === '1y') daysAgo = 365;
    
    const startDate = new Date(Date.now() - daysAgo * 24 * 60 * 60 * 1000);

    const result = await query(
      `SELECT 
        DATE(s.created_at) as date,
        COUNT(*) as count,
        sc.name as category
       FROM services s
       LEFT JOIN service_categories sc ON s.category_id = sc.id
       WHERE s.created_at >= $1
       GROUP BY DATE(s.created_at), sc.name
       ORDER BY date ASC`,
      [startDate]
    );

    res.json({
      success: true,
      stats: result.rows
    });

  } catch (error) {
    console.error('Get service stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Get all documents from providers
export const getAllDocuments = async (req, res) => {
  try {
    const { page = 1, limit = 20, category } = req.query;
    const offset = (page - 1) * limit;

    let whereClause = '';
    let params = [limit, offset];

    if (category && ['certificates', 'documents'].includes(category)) {
      whereClause = 'WHERE $3 = ANY(document_types)';
      params.push(category);
    }

    // Get provider documents and certificates
    const result = await query(
      `SELECT 
        pp.id as provider_id,
        pp.business_name,
        pp.documents,
        pp.certificates,
        pp.created_at as upload_date,
        u.name as provider_name,
        u.email as provider_email,
        pp.provider_type
       FROM provider_profiles pp
       JOIN users u ON pp.user_id = u.id
       WHERE (pp.documents IS NOT NULL AND pp.documents != '{}') 
          OR (pp.certificates IS NOT NULL AND pp.certificates != '{}')
       ORDER BY pp.created_at DESC
       LIMIT $1 OFFSET $2`,
      [limit, offset]
    );

    // Get total count
    const countResult = await query(
      `SELECT COUNT(*) as total FROM provider_profiles pp
       WHERE (pp.documents IS NOT NULL AND pp.documents != '{}') 
          OR (pp.certificates IS NOT NULL AND pp.certificates != '{}')`,
      []
    );

    const total = parseInt(countResult.rows[0].total);

    // Transform the data to match frontend expectations
    const documents = [];
    
    result.rows.forEach(provider => {
      // Process documents
      if (provider.documents && typeof provider.documents === 'object') {
        Object.entries(provider.documents).forEach(([key, doc]) => {
          if (doc && typeof doc === 'object') {
            documents.push({
              id: `doc_${provider.provider_id}_${key}`,
              name: doc.name || `${key}.pdf`,
              type: 'document',
              size: doc.size || 1024000,
              uploadDate: provider.upload_date,
              uploadedBy: {
                name: provider.provider_name,
                email: provider.provider_email
              },
              category: 'provider_documents',
              url: doc.url || `/documents/${key}`,
              providerId: provider.provider_id,
              businessName: provider.business_name
            });
          }
        });
      }

      // Process certificates
      if (provider.certificates && typeof provider.certificates === 'object') {
        Object.entries(provider.certificates).forEach(([key, cert]) => {
          if (cert && typeof cert === 'object') {
            documents.push({
              id: `cert_${provider.provider_id}_${key}`,
              name: cert.name || `${key}_certificate.pdf`,
              type: 'certificate',
              size: cert.size || 2048000,
              uploadDate: provider.upload_date,
              uploadedBy: {
                name: provider.provider_name,
                email: provider.provider_email
              },
              category: 'certificates',
              url: cert.url || `/certificates/${key}`,
              providerId: provider.provider_id,
              businessName: provider.business_name
            });
          }
        });
      }
    });

    // Apply category filter if specified
    let filteredDocuments = documents;
    if (category) {
      filteredDocuments = documents.filter(doc => doc.category === category);
    }

    res.json({
      success: true,
      documents: filteredDocuments,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: filteredDocuments.length,
        pages: Math.ceil(filteredDocuments.length / limit)
      }
    });

  } catch (error) {
    console.error('Get all documents error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Delete document
export const deleteDocument = async (req, res) => {
  try {
    const { documentId } = req.params;
    const adminId = req.user.id;

    // Parse document ID to get provider ID and document key
    const [type, providerId, docKey] = documentId.split('_');
    
    if (!providerId || !docKey) {
      return res.status(400).json({
        success: false,
        message: 'Invalid document ID format'
      });
    }

    // Get provider info first
    const providerResult = await query(
      'SELECT business_name, documents, certificates FROM provider_profiles WHERE id = $1',
      [providerId]
    );

    if (providerResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Provider not found'
      });
    }

    const provider = providerResult.rows[0];
    let updatedData = {};
    let documentName = '';

    if (type === 'doc' && provider.documents) {
      const documents = { ...provider.documents };
      documentName = documents[docKey]?.name || docKey;
      delete documents[docKey];
      updatedData.documents = documents;
    } else if (type === 'cert' && provider.certificates) {
      const certificates = { ...provider.certificates };
      documentName = certificates[docKey]?.name || docKey;
      delete certificates[docKey];
      updatedData.certificates = certificates;
    } else {
      return res.status(404).json({
        success: false,
        message: 'Document not found'
      });
    }

    // Update provider profile
    const updateQuery = type === 'doc' 
      ? 'UPDATE provider_profiles SET documents = $1, updated_at = NOW() WHERE id = $2'
      : 'UPDATE provider_profiles SET certificates = $1, updated_at = NOW() WHERE id = $2';
    
    await query(updateQuery, [JSON.stringify(updatedData[type === 'doc' ? 'documents' : 'certificates']), providerId]);

    // Log the activity
    await logActivity(
      'document_deletion',
      `Document "${documentName}" was deleted from provider ${provider.business_name}`,
      null,
      adminId,
      'warning',
      { document_id: documentId, provider_id: providerId, document_name: documentName }
    );

    res.json({
      success: true,
      message: 'Document deleted successfully'
    });

  } catch (error) {
    console.error('Delete document error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Settings Management Functions

// Get all application settings
export const getAppSettings = async (req, res) => {
  try {
    const { category } = req.query;
    
    let whereClause = '';
    let params = [];
    
    if (category) {
      whereClause = 'WHERE category = $1';
      params.push(category);
    }
    
    const result = await query(
      `SELECT key, value, description, category, is_public, updated_at
       FROM app_settings
       ${whereClause}
       ORDER BY category, key`,
      params
    );

    // Group settings by category
    const settingsByCategory = {};
    result.rows.forEach(setting => {
      if (!settingsByCategory[setting.category]) {
        settingsByCategory[setting.category] = [];
      }
      settingsByCategory[setting.category].push({
        key: setting.key,
        value: setting.value,
        description: setting.description,
        isPublic: setting.is_public,
        updatedAt: setting.updated_at
      });
    });

    res.json({
      success: true,
      settings: settingsByCategory
    });

  } catch (error) {
    console.error('Get app settings error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Update application setting
export const updateAppSetting = async (req, res) => {
  try {
    const { key } = req.params;
    const { value } = req.body;
    const adminId = req.user.id;

    // Check if setting exists
    const settingCheck = await query(
      'SELECT key, description FROM app_settings WHERE key = $1',
      [key]
    );

    if (settingCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Setting not found'
      });
    }

    // Update the setting
    const result = await query(
      `UPDATE app_settings 
       SET value = $1, updated_at = NOW()
       WHERE key = $2
       RETURNING key, value, description, category`,
      [value, key]
    );

    // Log the activity
    await logActivity(
      'setting_update',
      `Application setting "${key}" was updated to "${value}"`,
      null,
      adminId,
      'info',
      { setting_key: key, old_value: settingCheck.rows[0].value, new_value: value }
    );

    res.json({
      success: true,
      message: 'Setting updated successfully',
      setting: result.rows[0]
    });

  } catch (error) {
    console.error('Update app setting error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Get admin preferences
export const getAdminPreferences = async (req, res) => {
  try {
    const adminId = req.user.id;

    const result = await query(
      'SELECT preferences FROM admin_preferences WHERE admin_id = $1',
      [adminId]
    );

    const preferences = result.rows.length > 0 
      ? result.rows[0].preferences 
      : {
          notifications: {
            email: true,
            providerApprovals: true,
            systemAlerts: true,
            userRegistrations: true
          },
          display: {
            language: 'en',
            timezone: 'Africa/Addis_Ababa',
            dateFormat: 'MM/dd/yyyy',
            theme: 'light'
          },
          dashboard: {
            defaultView: 'overview',
            refreshInterval: 30000,
            showWelcomeMessage: true
          }
        };

    res.json({
      success: true,
      preferences
    });

  } catch (error) {
    console.error('Get admin preferences error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Update admin preferences
export const updateAdminPreferences = async (req, res) => {
  try {
    const adminId = req.user.id;
    const { preferences } = req.body;

    // Upsert preferences
    const result = await query(
      `INSERT INTO admin_preferences (admin_id, preferences, updated_at)
       VALUES ($1, $2, NOW())
       ON CONFLICT (admin_id)
       DO UPDATE SET preferences = $2, updated_at = NOW()
       RETURNING preferences`,
      [adminId, JSON.stringify(preferences)]
    );

    // Log the activity
    await logActivity(
      'preferences_update',
      'Admin preferences were updated',
      null,
      adminId,
      'info',
      { updated_preferences: Object.keys(preferences) }
    );

    res.json({
      success: true,
      message: 'Preferences updated successfully',
      preferences: result.rows[0].preferences
    });

  } catch (error) {
    console.error('Update admin preferences error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Update admin profile
export const updateAdminProfile = async (req, res) => {
  try {
    const adminId = req.user.id;
    const { name, email } = req.body;

    // Check if email is already taken by another user
    if (email) {
      const emailCheck = await query(
        'SELECT id FROM users WHERE email = $1 AND id != $2',
        [email, adminId]
      );

      if (emailCheck.rows.length > 0) {
        return res.status(400).json({
          success: false,
          message: 'Email is already in use by another account'
        });
      }
    }

    // Update user profile
    const updateFields = [];
    const updateValues = [];
    let paramCount = 1;

    if (name) {
      updateFields.push(`name = $${paramCount}`);
      updateValues.push(name);
      paramCount++;
    }

    if (email) {
      updateFields.push(`email = $${paramCount}`);
      updateValues.push(email);
      paramCount++;
    }

    if (updateFields.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No fields to update'
      });
    }

    updateFields.push(`updated_at = NOW()`);
    updateValues.push(adminId);

    const result = await query(
      `UPDATE users 
       SET ${updateFields.join(', ')}
       WHERE id = $${paramCount}
       RETURNING id, name, email, role`,
      updateValues
    );

    // Log the activity
    await logActivity(
      'profile_update',
      'Admin profile was updated',
      adminId,
      adminId,
      'info',
      { updated_fields: updateFields.filter(f => !f.includes('updated_at')) }
    );

    res.json({
      success: true,
      message: 'Profile updated successfully',
      user: result.rows[0]
    });

  } catch (error) {
    console.error('Update admin profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Change admin password
export const changeAdminPassword = async (req, res) => {
  try {
    const adminId = req.user.id;
    const { currentPassword, newPassword } = req.body;

    // Get current password hash
    const userResult = await query(
      'SELECT password_hash FROM users WHERE id = $1',
      [adminId]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Verify current password
    const bcrypt = await import('bcryptjs');
    const isValidPassword = await bcrypt.compare(currentPassword, userResult.rows[0].password_hash);

    if (!isValidPassword) {
      return res.status(400).json({
        success: false,
        message: 'Current password is incorrect'
      });
    }

    // Hash new password
    const saltRounds = 10;
    const newPasswordHash = await bcrypt.hash(newPassword, saltRounds);

    // Update password
    await query(
      'UPDATE users SET password_hash = $1, updated_at = NOW() WHERE id = $2',
      [newPasswordHash, adminId]
    );

    // Log the activity
    await logActivity(
      'password_change',
      'Admin password was changed',
      adminId,
      adminId,
      'security',
      { timestamp: new Date().toISOString() }
    );

    res.json({
      success: true,
      message: 'Password changed successfully'
    });

  } catch (error) {
    console.error('Change admin password error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Get system information
export const getSystemInfo = async (req, res) => {
  try {
    // Get database stats
    const dbStats = await query(`
      SELECT 
        (SELECT COUNT(*) FROM users) as total_users,
        (SELECT COUNT(*) FROM provider_profiles) as total_providers,
        (SELECT COUNT(*) FROM services) as total_services,
        (SELECT COUNT(*) FROM service_requests) as total_requests,
        (SELECT COUNT(*) FROM activity_logs) as total_logs
    `);

    // Get recent activity
    const recentActivity = await query(`
      SELECT type, description, created_at
      FROM activity_logs
      ORDER BY created_at DESC
      LIMIT 5
    `);

    const systemInfo = {
      database: {
        totalUsers: parseInt(dbStats.rows[0].total_users),
        totalProviders: parseInt(dbStats.rows[0].total_providers),
        totalServices: parseInt(dbStats.rows[0].total_services),
        totalRequests: parseInt(dbStats.rows[0].total_requests),
        totalLogs: parseInt(dbStats.rows[0].total_logs)
      },
      server: {
        nodeVersion: process.version,
        platform: process.platform,
        uptime: process.uptime(),
        memoryUsage: process.memoryUsage()
      },
      recentActivity: recentActivity.rows
    };

    res.json({
      success: true,
      systemInfo
    });

  } catch (error) {
    console.error('Get system info error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};