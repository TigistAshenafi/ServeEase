import { query } from '../config/database.js';
import nodemailer from 'nodemailer';

// Email transporter
const transporter = nodemailer.createTransport({
  service : "gmail",
  secure: false,
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

// Create service request
const createServiceRequest = async (req, res) => {
  try {
    const seekerId = req.user.id;
    const { serviceId, notes } = req.body;

    // Validate required fields
    if (!serviceId) {
      return res.status(400).json({
        success: false,
        message: 'Service ID is required'
      });
    }

    // Check if service exists and is active
    const serviceResult = await query(
      `SELECT s.*, pp.business_name, pp.user_id as provider_user_id, u.email as provider_email
       FROM services s
       JOIN provider_profiles pp ON s.provider_id = pp.id
       JOIN users u ON pp.user_id = u.id
       WHERE s.id = $1 AND s.is_active = true`,
      [serviceId]
    );

    if (serviceResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Service not found or unavailable'
      });
    }

    const service = serviceResult.rows[0];

    // Create service request
    const result = await query(
      `INSERT INTO service_requests (seeker_id, service_id, provider_id, notes)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [seekerId, serviceId, service.provider_id, notes]
    );

    const request = result.rows[0];

    // Send notification email to provider
    try {
      const seekerResult = await query('SELECT name FROM users WHERE id = $1', [seekerId]);
      const seeker = seekerResult.rows[0];

      await transporter.sendMail({
        from: process.env.EMAIL_FROM,
        to: service.provider_email,
        subject: 'New Service Request - ServeEase',
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h2>New Service Request!</h2>
            <p>Hello ${service.business_name},</p>
            <p>You have received a new service request from ${seeker.name}.</p>
            <div style="background-color: #f5f5f5; padding: 15px; border-radius: 8px; margin: 15px 0;">
              <h3>Service: ${service.title}</h3>
              <p><strong>Price:</strong> \$${service.price}</p>
              <p><strong>Duration:</strong> ${service.duration_hours} hours</p>
              ${notes ? `<p><strong>Client Notes:</strong> ${notes}</p>` : ''}
            </div>
            <p>Please log in to your ServeEase account to respond to this request.</p>
            <p>Best regards,<br>The ServeEase Team</p>
          </div>
        `,
      });
    } catch (emailError) {
      console.error('Service request notification email failed:', emailError);
    }

    res.status(201).json({
      success: true,
      message: 'Service request created successfully',
      request: {
        id: request.id,
        serviceId: request.service_id,
        providerId: request.provider_id,
        status: request.status,
        notes: request.notes,
        createdAt: request.created_at,
      }
    });

  } catch (error) {
    console.error('Create service request error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Get user's service requests (both seeker and provider view)
const getServiceRequests = async (req, res) => {
  try {
    const userId = req.user.id;
    const { status, page = 1, limit = 10 } = req.query;
    const offset = (page - 1) * limit;

    // Get user role
    const userResult = await query('SELECT role FROM users WHERE id = $1', [userId]);
    const userRole = userResult.rows[0].role;

    let whereClause = '';
    let params = [userId, limit, offset];

    if (userRole === 'seeker') {
      whereClause = 'WHERE sr.seeker_id = $1';
    } else if (userRole === 'provider') {
      // Get provider profile ID first
      const providerResult = await query(
        'SELECT id FROM provider_profiles WHERE user_id = $1',
        [userId]
      );

      if (providerResult.rows.length === 0) {
        return res.json({
          success: true,
          requests: [],
          pagination: { page: 1, limit: parseInt(limit), total: 0, pages: 0 }
        });
      }

      whereClause = 'WHERE sr.provider_id = $1';
      params[0] = providerResult.rows[0].id;
    } else {
      // Admin can see all
      whereClause = '';
      params = [limit, offset];
    }

    if (status && status !== 'all') {
      const statusCondition = whereClause ? ' AND sr.status = $4' : 'WHERE sr.status = $1';
      whereClause += statusCondition;
      params.splice(whereClause ? 3 : 0, 0, status);
    }

    const result = await query(
      `SELECT sr.*, s.title as service_title, s.price as service_price, s.duration_hours,
              pp.business_name as provider_business_name, pp.location as provider_location,
              u_seeker.name as seeker_name, u_seeker.email as seeker_email,
              u_provider.name as provider_name, u_provider.email as provider_email
       FROM service_requests sr
       JOIN services s ON sr.service_id = s.id
       JOIN provider_profiles pp ON sr.provider_id = pp.id
       JOIN users u_seeker ON sr.seeker_id = u_seeker.id
       JOIN users u_provider ON pp.user_id = u_provider.id
       ${whereClause}
       ORDER BY sr.created_at DESC
       LIMIT $${whereClause ? params.length - 1 : params.length - 1} OFFSET $${whereClause ? params.length : params.length}`,
      params
    );

    // Get total count
    const countQuery = `SELECT COUNT(*) as total FROM service_requests sr ${whereClause}`;
    const countParams = whereClause ? params.slice(0, -2) : [];
    const countResult = await query(countQuery, countParams);

    const total = parseInt(countResult.rows[0].total);

    res.json({
      success: true,
      requests: result.rows.map(request => ({
        id: request.id,
        seekerId: request.seeker_id,
        serviceId: request.service_id,
        providerId: request.provider_id,
        status: request.status,
        requestedDate: request.requested_date,
        scheduledDate: request.scheduled_date,
        completionDate: request.completion_date,
        notes: request.notes,
        seekerRating: request.seeker_rating,
        seekerReview: request.seeker_review,
        providerRating: request.provider_rating,
        providerReview: request.provider_review,
        service: {
          title: request.service_title,
          price: parseFloat(request.service_price),
          durationHours: request.duration_hours,
        },
        seeker: {
          name: request.seeker_name,
          email: request.seeker_email,
        },
        provider: {
          businessName: request.provider_business_name,
          location: request.provider_location,
          name: request.provider_name,
          email: request.provider_email,
        },
        createdAt: request.created_at,
        updatedAt: request.updated_at,
      })),
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });

  } catch (error) {
    console.error('Get service requests error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Assign employee to service request
const assignEmployee = async (req, res) => {
  try {
    const userId = req.user.id;
    const { requestId } = req.params;
    const { employeeId } = req.body;

    // Get user role and provider profile
    const userResult = await query('SELECT role FROM users WHERE id = $1', [userId]);
    const userRole = userResult.rows[0].role;

    let providerId;
    if (userRole === 'provider') {
      const providerResult = await query(
        'SELECT id FROM provider_profiles WHERE user_id = $1',
        [userId]
      );

      if (providerResult.rows.length === 0) {
        return res.status(403).json({
          success: false,
          message: 'Provider profile not found'
        });
      }

      providerId = providerResult.rows[0].id;
    }

    // Get service request details
    const requestResult = await query(
      `SELECT sr.*, pp.provider_type
       FROM service_requests sr
       JOIN provider_profiles pp ON sr.provider_id = pp.id
       WHERE sr.id = $1`,
      [requestId]
    );

    if (requestResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Service request not found'
      });
    }

    const request = requestResult.rows[0];

    // Check permissions
    if (userRole !== 'admin' && request.provider_id !== providerId) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    // Only organizations can assign employees
    if (request.provider_type !== 'organization') {
      return res.status(400).json({
        success: false,
        message: 'Only organizations can assign employees to service requests'
      });
    }

    // Verify employee belongs to the organization
    const employeeResult = await query(
      'SELECT id FROM employees WHERE id = $1 AND organization_id = $2 AND is_active = true',
      [employeeId, request.provider_id]
    );

    if (employeeResult.rows.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Employee not found or not available'
      });
    }

    // Assign employee and update status
    const result = await query(
      `UPDATE service_requests
       SET assigned_employee_id = $1, status = 'assigned', updated_at = NOW()
       WHERE id = $2
       RETURNING *`,
      [employeeId, requestId]
    );

    res.json({
      success: true,
      message: 'Employee assigned successfully',
      request: {
        id: result.rows[0].id,
        status: result.rows[0].status,
        assignedEmployeeId: result.rows[0].assigned_employee_id,
        updatedAt: result.rows[0].updated_at,
      }
    });

  } catch (error) {
    console.error('Assign employee error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Update service request status
const updateServiceRequestStatus = async (req, res) => {
  try {
    const userId = req.user.id;
    const { requestId } = req.params;
    const { status, scheduledDate, completionDate, notes } = req.body;

    // Validate status
    const validStatuses = ['pending', 'accepted', 'assigned', 'in_progress', 'completed', 'cancelled'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid status'
      });
    }

    // Get user role and check permissions
    const userResult = await query('SELECT role FROM users WHERE id = $1', [userId]);
    const userRole = userResult.rows[0].role;

    let permissionCheck = '';
    if (userRole === 'provider') {
      // Check if provider owns this request
      const providerResult = await query(
        'SELECT pp.id FROM provider_profiles pp WHERE pp.user_id = $1',
        [userId]
      );

      if (providerResult.rows.length === 0) {
        return res.status(403).json({
          success: false,
          message: 'Access denied'
        });
      }

      permissionCheck = 'AND sr.provider_id = $3';
    } else if (userRole === 'seeker') {
      // Check if seeker owns this request
      permissionCheck = 'AND sr.seeker_id = $3';
    }

    // Update request
    const updateFields = [];
    const updateParams = [status, notes];
    let paramCount = 3;

    updateFields.push('status = $1');
    if (scheduledDate) {
      updateFields.push(`scheduled_date = $${paramCount++}`);
      updateParams.push(scheduledDate);
    }
    if (completionDate) {
      updateFields.push(`completion_date = $${paramCount++}`);
      updateParams.push(completionDate);
    }
    if (notes) {
      updateFields.push('notes = $2');
    }

    updateParams.push(requestId);
    if (permissionCheck) {
      if (userRole === 'provider') {
        const providerResult = await query(
          'SELECT id FROM provider_profiles WHERE user_id = $1',
          [userId]
        );
        updateParams.push(providerResult.rows[0].id);
      } else {
        updateParams.push(userId);
      }
    }

    const result = await query(
      `UPDATE service_requests
       SET ${updateFields.join(', ')}, updated_at = NOW()
       WHERE id = $${paramCount - 1} ${permissionCheck}
       RETURNING *`,
      updateParams
    );

    if (result.rowCount === 0) {
      return res.status(404).json({
        success: false,
        message: 'Service request not found or access denied'
      });
    }

    const request = result.rows[0];

    res.json({
      success: true,
      message: 'Service request updated successfully',
      request: {
        id: request.id,
        status: request.status,
        scheduledDate: request.scheduled_date,
        completionDate: request.completion_date,
        notes: request.notes,
        updatedAt: request.updated_at,
      }
    });

  } catch (error) {
    console.error('Update service request status error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Add rating and review
const addRatingAndReview = async (req, res) => {
  try {
    const userId = req.user.id;
    const { requestId } = req.params;
    const { rating, review, isProviderReview = false } = req.body;

    // Validate rating
    if (rating < 1 || rating > 5) {
      return res.status(400).json({
        success: false,
        message: 'Rating must be between 1 and 5'
      });
    }

    // Get user role
    const userResult = await query('SELECT role FROM users WHERE id = $1', [userId]);
    const userRole = userResult.rows[0].role;

    let permissionCheck = '';
    let ratingField, reviewField;

    if (userRole === 'seeker') {
      permissionCheck = 'AND seeker_id = $1';
      ratingField = 'seeker_rating';
      reviewField = 'seeker_review';
    } else if (userRole === 'provider') {
      // Check if provider owns this request
      const providerResult = await query(
        'SELECT pp.id FROM provider_profiles pp WHERE pp.user_id = $1',
        [userId]
      );

      if (providerResult.rows.length === 0) {
        return res.status(403).json({
          success: false,
          message: 'Access denied'
        });
      }

      permissionCheck = 'AND provider_id = $1';
      ratingField = 'provider_rating';
      reviewField = 'provider_review';
    } else {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    // Check if request exists and belongs to user
    const checkParams = userRole === 'provider'
      ? [providerResult.rows[0].id]
      : [userId];

    const checkResult = await query(
      `SELECT id FROM service_requests WHERE id = $2 ${permissionCheck}`,
      [...checkParams, requestId]
    );

    if (checkResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Service request not found or access denied'
      });
    }

    // Add rating and review
    const result = await query(
      `UPDATE service_requests
       SET ${ratingField} = $1, ${reviewField} = $2, updated_at = NOW()
       WHERE id = $3
       RETURNING *`,
      [rating, review, requestId]
    );

    res.json({
      success: true,
      message: 'Rating and review added successfully',
      rating: {
        rating: result.rows[0][ratingField],
        review: result.rows[0][reviewField],
      }
    });

  } catch (error) {
    console.error('Add rating and review error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

export {
  createServiceRequest,
  getServiceRequests,
  assignEmployee,
  updateServiceRequestStatus,
  addRatingAndReview
};
