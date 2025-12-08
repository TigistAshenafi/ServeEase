import { query } from '../config/database.js';

// Get all service categories
const getServiceCategories = async (req, res) => {
  try {
    const result = await query(
      'SELECT * FROM service_categories ORDER BY name',
      []
    );

    res.json({
      success: true,
      categories: result.rows.map(category => ({
        id: category.id,
        name: category.name,
        description: category.description,
        icon: category.icon,
      }))
    });
  } catch (error) {
    console.error('Get service categories error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Get services by category
const getServicesByCategory = async (req, res) => {
  try {
    const { categoryId } = req.params;
    const { page = 1, limit = 10 } = req.query;
    const offset = (page - 1) * limit;

    const result = await query(
      `SELECT s.*, pp.business_name, pp.location, u.name as provider_name
       FROM services s
       JOIN provider_profiles pp ON s.provider_id = pp.id
       JOIN users u ON pp.user_id = u.id
       WHERE s.category_id = $1 AND s.is_active = true
       ORDER BY s.created_at DESC
       LIMIT $2 OFFSET $3`,
      [categoryId, limit, offset]
    );

    // Get total count
    const countResult = await query(
      'SELECT COUNT(*) as total FROM services WHERE category_id = $1 AND is_active = true',
      [categoryId]
    );

    const total = parseInt(countResult.rows[0].total);

    res.json({
      success: true,
      services: result.rows.map(service => ({
        id: service.id,
        title: service.title,
        description: service.description,
        price: parseFloat(service.price),
        durationHours: service.duration_hours,
        categoryId: service.category_id,
        provider: {
          id: service.provider_id,
          businessName: service.business_name,
          location: service.location,
          name: service.provider_name,
        },
        createdAt: service.created_at,
        updatedAt: service.updated_at,
      })),
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });

  } catch (error) {
    console.error('Get services by category error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Get provider's services
const getProviderServices = async (req, res) => {
  try {
    const userId = req.user.id;
    const { page = 1, limit = 10 } = req.query;
    const offset = (page - 1) * limit;

    // First get provider profile ID
    const providerResult = await query(
      'SELECT id FROM provider_profiles WHERE user_id = $1',
      [userId]
    );

    if (providerResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Provider profile not found'
      });
    }

    const providerId = providerResult.rows[0].id;

    const result = await query(
      `SELECT s.*, sc.name as category_name, sc.icon as category_icon
       FROM services s
       JOIN service_categories sc ON s.category_id = sc.id
       WHERE s.provider_id = $1
       ORDER BY s.created_at DESC
       LIMIT $2 OFFSET $3`,
      [providerId, limit, offset]
    );

    // Get total count
    const countResult = await query(
      'SELECT COUNT(*) as total FROM services WHERE provider_id = $1',
      [providerId]
    );

    const total = parseInt(countResult.rows[0].total);

    res.json({
      success: true,
      services: result.rows.map(service => ({
        id: service.id,
        title: service.title,
        description: service.description,
        price: parseFloat(service.price),
        durationHours: service.duration_hours,
        categoryId: service.category_id,
        categoryName: service.category_name,
        categoryIcon: service.category_icon,
        isActive: service.is_active,
        createdAt: service.created_at,
        updatedAt: service.updated_at,
      })),
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });

  } catch (error) {
    console.error('Get provider services error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Create service
const createService = async (req, res) => {
  try {
    const userId = req.user.id;
    const { title, description, categoryId, price, durationHours } = req.body;

    // Validate required fields
    if (!title || !description || !categoryId || price == null || durationHours == null) {
      return res.status(400).json({
        success: false,
        message: 'All fields are required'
      });
    }

    // Check if provider is approved
    const providerResult = await query(
      'SELECT id, is_approved FROM provider_profiles WHERE user_id = $1',
      [userId]
    );

    if (providerResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Provider profile not found'
      });
    }

    const provider = providerResult.rows[0];
    if (!provider.is_approved) {
      return res.status(403).json({
        success: false,
        message: 'Provider account must be approved to create services'
      });
    }

    // Check if category exists
    const categoryResult = await query(
      'SELECT id FROM service_categories WHERE id = $1',
      [categoryId]
    );

    if (categoryResult.rows.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Invalid service category'
      });
    }

    // Create service
    const result = await query(
      `INSERT INTO services (provider_id, category_id, title, description, price, duration_hours)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [provider.id, categoryId, title, description, price, durationHours]
    );

    const service = result.rows[0];

    res.status(201).json({
      success: true,
      message: 'Service created successfully',
      service: {
        id: service.id,
        title: service.title,
        description: service.description,
        price: parseFloat(service.price),
        durationHours: service.duration_hours,
        categoryId: service.category_id,
        isActive: service.is_active,
        createdAt: service.created_at,
        updatedAt: service.updated_at,
      }
    });

  } catch (error) {
    console.error('Create service error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Update service
const updateService = async (req, res) => {
  try {
    const userId = req.user.id;
    const { serviceId } = req.params;
    const { title, description, categoryId, price, durationHours, isActive } = req.body;

    // Get provider profile ID
    const providerResult = await query(
      'SELECT id FROM provider_profiles WHERE user_id = $1',
      [userId]
    );

    if (providerResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Provider profile not found'
      });
    }

    const providerId = providerResult.rows[0].id;

    // Check if service belongs to this provider
    const serviceResult = await query(
      'SELECT id FROM services WHERE id = $1 AND provider_id = $2',
      [serviceId, providerId]
    );

    if (serviceResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Service not found or access denied'
      });
    }

    // Update service
    const result = await query(
      `UPDATE services
       SET title = $1, description = $2, category_id = $3, price = $4, duration_hours = $5, is_active = $6, updated_at = NOW()
       WHERE id = $7
       RETURNING *`,
      [title, description, categoryId, price, durationHours, isActive, serviceId]
    );

    const service = result.rows[0];

    res.json({
      success: true,
      message: 'Service updated successfully',
      service: {
        id: service.id,
        title: service.title,
        description: service.description,
        price: parseFloat(service.price),
        durationHours: service.duration_hours,
        categoryId: service.category_id,
        isActive: service.is_active,
        createdAt: service.created_at,
        updatedAt: service.updated_at,
      }
    });

  } catch (error) {
    console.error('Update service error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Delete service
const deleteService = async (req, res) => {
  try {
    const userId = req.user.id;
    const { serviceId } = req.params;

    // Get provider profile ID
    const providerResult = await query(
      'SELECT id FROM provider_profiles WHERE user_id = $1',
      [userId]
    );

    if (providerResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Provider profile not found'
      });
    }

    const providerId = providerResult.rows[0].id;

    // Delete service (soft delete by setting is_active to false)
    const result = await query(
      'UPDATE services SET is_active = false, updated_at = NOW() WHERE id = $1 AND provider_id = $2',
      [serviceId, providerId]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({
        success: false,
        message: 'Service not found or access denied'
      });
    }

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

export {
  getServiceCategories,
  getServicesByCategory,
  getProviderServices,
  createService,
  updateService,
  deleteService
};
