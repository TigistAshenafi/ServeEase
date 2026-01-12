import { query } from '../config/database.js';

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

    const result = await query(
      `UPDATE users
       SET is_active = true, suspended_at = NULL, suspension_reason = NULL, updated_at = NOW()
       WHERE id = $1
       RETURNING id, name, email, is_active`,
      [userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

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

    let whereClause = '';
    let params = [limit, offset];

    if (status === 'active') {
      whereClause = 'WHERE s.is_active = true';
    } else if (status === 'inactive') {
      whereClause = 'WHERE s.is_active = false';
    }

    const result = await query(
      `SELECT s.*, 
              pp.business_name, pp.user_id,
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
      `SELECT COUNT(*) as total FROM services s ${whereClause}`,
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
        price: parseFloat(service.price),
        durationHours: service.duration_hours,
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

    // For now, return mock data since we don't have an activity_logs table
    // In production, you would create an activity_logs table and log all admin actions
    
    res.json({
      success: true,
      logs: [],
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: 0,
        pages: 0
      }
    });

  } catch (error) {
    console.error('Get activity logs error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
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