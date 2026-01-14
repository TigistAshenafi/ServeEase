import nodemailer from 'nodemailer';
import { query } from '../config/database.js';

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

    // Automatically create chat conversation for this request
    try {
      const conversationResult = await query(
        `INSERT INTO conversations (service_request_id, seeker_id, provider_id)
         VALUES ($1, $2, $3)
         RETURNING *`,
        [request.id, seekerId, service.provider_user_id]
      );

      const conversation = conversationResult.rows[0];

      // Add participants to conversation
      await query(
        `INSERT INTO conversation_participants (conversation_id, user_id, role)
         VALUES ($1, $2, 'member'), ($1, $3, 'member')`,
        [conversation.id, seekerId, service.provider_user_id]
      );

      // Send initial system message
      await query(
        `INSERT INTO messages (conversation_id, sender_id, message_type, content)
         VALUES ($1, $2, 'system', $3)`,
        [conversation.id, seekerId, `Service request created for "${service.title}". You can now chat with your provider about the details.`]
      );

      console.log(`Chat conversation created for service request ${request.id}`);
    } catch (chatError) {
      console.error('Error creating chat conversation:', chatError);
      // Don't fail the request creation if chat fails
    }

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

// Accept service request (Provider only)
const acceptServiceRequest = async (req, res) => {
  try {
    console.log('Accept request called with:', {
      userId: req.user.id,
      requestId: req.params.requestId,
      body: req.body
    });

    const userId = req.user.id;
    const { requestId } = req.params;
    const { scheduledDate, notes } = req.body;

    // Get provider profile
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

    const providerId = providerResult.rows[0].id;

    // Check if request exists and belongs to provider
    const requestResult = await query(
      'SELECT * FROM service_requests WHERE id = $1 AND provider_id = $2',
      [requestId, providerId]
    );

    if (requestResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Service request not found or access denied'
      });
    }

    const request = requestResult.rows[0];

    // Check if request is in pending status
    if (request.status !== 'pending') {
      return res.status(400).json({
        success: false,
        message: `Cannot accept request with status: ${request.status}`
      });
    }

    // Update request to accepted
    const updateFields = ['status = $1', 'updated_at = NOW()'];
    const updateParams = ['accepted'];
    let paramCount = 2;

    if (scheduledDate) {
      updateFields.push(`scheduled_date = $${paramCount++}`);
      updateParams.push(scheduledDate);
    }

    if (notes) {
      updateFields.push(`notes = $${paramCount++}`);
      updateParams.push(notes);
    }

    updateParams.push(requestId);

    console.log('Executing update query with:', {
      updateFields: updateFields.join(', '),
      updateParams,
      paramCount
    });

    const result = await query(
      `UPDATE service_requests
       SET ${updateFields.join(', ')}
       WHERE id = $${paramCount}
       RETURNING *`,
      updateParams
    );

    console.log('Update result:', {
      rowCount: result.rowCount,
      updatedRequest: result.rows[0]
    });

    // Send notification email to seeker
    try {
      const seekerResult = await query('SELECT name, email FROM users WHERE id = $1', [request.seeker_id]);
      const serviceResult = await query('SELECT title FROM services WHERE id = $1', [request.service_id]);
      
      if (seekerResult.rows.length > 0 && serviceResult.rows.length > 0) {
        const seeker = seekerResult.rows[0];
        const service = serviceResult.rows[0];

        await transporter.sendMail({
          from: process.env.EMAIL_FROM,
          to: seeker.email,
          subject: 'Service Request Accepted - ServeEase',
          html: `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
              <h2>Great News! Your Service Request Has Been Accepted</h2>
              <p>Hello ${seeker.name},</p>
              <p>Your service request for "${service.title}" has been accepted by the provider.</p>
              ${scheduledDate ? `<p><strong>Scheduled Date:</strong> ${new Date(scheduledDate).toLocaleDateString()}</p>` : ''}
              ${notes ? `<p><strong>Provider Notes:</strong> ${notes}</p>` : ''}
              <p>You can track the progress of your request in your ServeEase dashboard.</p>
              <p>Best regards,<br>The ServeEase Team</p>
            </div>
          `,
        });
      }
    } catch (emailError) {
      console.error('Accept notification email failed:', emailError);
    }

    res.json({
      success: true,
      message: 'Service request accepted successfully',
      request: {
        id: result.rows[0].id,
        status: result.rows[0].status,
        scheduledDate: result.rows[0].scheduled_date,
        notes: result.rows[0].notes,
        updatedAt: result.rows[0].updated_at,
      }
    });

  } catch (error) {
    console.error('Accept service request error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Reject service request (Provider only)
const rejectServiceRequest = async (req, res) => {
  try {
    const userId = req.user.id;
    const { requestId } = req.params;
    const { reason } = req.body;

    // Get provider profile
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

    const providerId = providerResult.rows[0].id;

    // Check if request exists and belongs to provider
    const requestResult = await query(
      'SELECT * FROM service_requests WHERE id = $1 AND provider_id = $2',
      [requestId, providerId]
    );

    if (requestResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Service request not found or access denied'
      });
    }

    const request = requestResult.rows[0];

    // Check if request can be rejected
    if (!['pending', 'accepted'].includes(request.status)) {
      return res.status(400).json({
        success: false,
        message: `Cannot reject request with status: ${request.status}`
      });
    }

    // Update request to cancelled with reason
    const result = await query(
      `UPDATE service_requests
       SET status = 'cancelled', notes = $1, updated_at = NOW()
       WHERE id = $2
       RETURNING *`,
      [reason || 'Rejected by provider', requestId]
    );

    // Send notification email to seeker
    try {
      const seekerResult = await query('SELECT name, email FROM users WHERE id = $1', [request.seeker_id]);
      const serviceResult = await query('SELECT title FROM services WHERE id = $1', [request.service_id]);
      
      if (seekerResult.rows.length > 0 && serviceResult.rows.length > 0) {
        const seeker = seekerResult.rows[0];
        const service = serviceResult.rows[0];

        await transporter.sendMail({
          from: process.env.EMAIL_FROM,
          to: seeker.email,
          subject: 'Service Request Update - ServeEase',
          html: `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
              <h2>Service Request Update</h2>
              <p>Hello ${seeker.name},</p>
              <p>Unfortunately, your service request for "${service.title}" could not be fulfilled at this time.</p>
              ${reason ? `<p><strong>Reason:</strong> ${reason}</p>` : ''}
              <p>You can browse other providers or try again later.</p>
              <p>Best regards,<br>The ServeEase Team</p>
            </div>
          `,
        });
      }
    } catch (emailError) {
      console.error('Reject notification email failed:', emailError);
    }

    res.json({
      success: true,
      message: 'Service request rejected successfully',
      request: {
        id: result.rows[0].id,
        status: result.rows[0].status,
        notes: result.rows[0].notes,
        updatedAt: result.rows[0].updated_at,
      }
    });

  } catch (error) {
    console.error('Reject service request error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Start work on service request (Provider only)
const startServiceRequest = async (req, res) => {
  try {
    const userId = req.user.id;
    const { requestId } = req.params;
    const { notes } = req.body;

    // Get provider profile
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

    const providerId = providerResult.rows[0].id;

    // Check if request exists and belongs to provider
    const requestResult = await query(
      'SELECT * FROM service_requests WHERE id = $1 AND provider_id = $2',
      [requestId, providerId]
    );

    if (requestResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Service request not found or access denied'
      });
    }

    const request = requestResult.rows[0];

    // Check if request can be started
    if (!['accepted', 'assigned'].includes(request.status)) {
      return res.status(400).json({
        success: false,
        message: `Cannot start work on request with status: ${request.status}`
      });
    }

    // Update request to in_progress
    const result = await query(
      `UPDATE service_requests
       SET status = 'in_progress', notes = $1, updated_at = NOW()
       WHERE id = $2
       RETURNING *`,
      [notes || request.notes, requestId]
    );

    res.json({
      success: true,
      message: 'Work started on service request',
      request: {
        id: result.rows[0].id,
        status: result.rows[0].status,
        notes: result.rows[0].notes,
        updatedAt: result.rows[0].updated_at,
      }
    });

  } catch (error) {
    console.error('Start service request error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Complete service request (Provider only)
const completeServiceRequest = async (req, res) => {
  try {
    const userId = req.user.id;
    const { requestId } = req.params;
    const { notes, completionDate } = req.body;

    // Get provider profile
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

    const providerId = providerResult.rows[0].id;

    // Check if request exists and belongs to provider
    const requestResult = await query(
      'SELECT * FROM service_requests WHERE id = $1 AND provider_id = $2',
      [requestId, providerId]
    );

    if (requestResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Service request not found or access denied'
      });
    }

    const request = requestResult.rows[0];

    // Check if request can be completed
    if (request.status !== 'in_progress') {
      return res.status(400).json({
        success: false,
        message: `Cannot complete request with status: ${request.status}`
      });
    }

    // Update request to completed
    const result = await query(
      `UPDATE service_requests
       SET status = 'completed', 
           completion_date = $1, 
           notes = $2, 
           updated_at = NOW()
       WHERE id = $3
       RETURNING *`,
      [completionDate || new Date().toISOString(), notes || request.notes, requestId]
    );

    // Send completion notification email to seeker
    try {
      const seekerResult = await query('SELECT name, email FROM users WHERE id = $1', [request.seeker_id]);
      const serviceResult = await query('SELECT title FROM services WHERE id = $1', [request.service_id]);
      
      if (seekerResult.rows.length > 0 && serviceResult.rows.length > 0) {
        const seeker = seekerResult.rows[0];
        const service = serviceResult.rows[0];

        await transporter.sendMail({
          from: process.env.EMAIL_FROM,
          to: seeker.email,
          subject: 'Service Completed - ServeEase',
          html: `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
              <h2>Service Completed Successfully!</h2>
              <p>Hello ${seeker.name},</p>
              <p>Great news! Your service "${service.title}" has been completed.</p>
              <p><strong>Completion Date:</strong> ${new Date(result.rows[0].completion_date).toLocaleDateString()}</p>
              ${notes ? `<p><strong>Provider Notes:</strong> ${notes}</p>` : ''}
              <p>Please consider leaving a rating and review for this service.</p>
              <p>Thank you for using ServeEase!</p>
              <p>Best regards,<br>The ServeEase Team</p>
            </div>
          `,
        });
      }
    } catch (emailError) {
      console.error('Completion notification email failed:', emailError);
    }

    res.json({
      success: true,
      message: 'Service request completed successfully',
      request: {
        id: result.rows[0].id,
        status: result.rows[0].status,
        completionDate: result.rows[0].completion_date,
        notes: result.rows[0].notes,
        updatedAt: result.rows[0].updated_at,
      }
    });

  } catch (error) {
    console.error('Complete service request error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Cancel service request (Seeker or Provider)
const cancelServiceRequest = async (req, res) => {
  try {
    const userId = req.user.id;
    const { requestId } = req.params;
    const { reason } = req.body;

    // Get user role
    const userResult = await query('SELECT role FROM users WHERE id = $1', [userId]);
    const userRole = userResult.rows[0].role;

    let permissionCheck = '';
    let checkParams = [requestId];

    if (userRole === 'seeker') {
      permissionCheck = 'AND seeker_id = $2';
      checkParams.push(userId);
    } else if (userRole === 'provider') {
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

      permissionCheck = 'AND provider_id = $2';
      checkParams.push(providerResult.rows[0].id);
    } else {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    // Check if request exists and belongs to user
    const requestResult = await query(
      `SELECT * FROM service_requests WHERE id = $1 ${permissionCheck}`,
      checkParams
    );

    if (requestResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Service request not found or access denied'
      });
    }

    const request = requestResult.rows[0];

    // Check if request can be cancelled
    if (['completed', 'cancelled'].includes(request.status)) {
      return res.status(400).json({
        success: false,
        message: `Cannot cancel request with status: ${request.status}`
      });
    }

    // Update request to cancelled
    const result = await query(
      `UPDATE service_requests
       SET status = 'cancelled', notes = $1, updated_at = NOW()
       WHERE id = $2
       RETURNING *`,
      [reason || `Cancelled by ${userRole}`, requestId]
    );

    res.json({
      success: true,
      message: 'Service request cancelled successfully',
      request: {
        id: result.rows[0].id,
        status: result.rows[0].status,
        notes: result.rows[0].notes,
        updatedAt: result.rows[0].updated_at,
      }
    });

  } catch (error) {
    console.error('Cancel service request error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Get single service request with full details
const getServiceRequestDetails = async (req, res) => {
  try {
    const userId = req.user.id;
    const { requestId } = req.params;

    console.log(`Getting request details for ID: ${requestId}, User: ${userId}`);

    // Basic validation
    if (!requestId || requestId.trim() === '') {
      return res.status(400).json({
        success: false,
        message: 'Request ID is required'
      });
    }

    // Get user role
    const userResult = await query('SELECT role FROM users WHERE id = $1', [userId]);
    
    if (userResult.rows.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'User not found'
      });
    }

    const userRole = userResult.rows[0].role;
    console.log(`User role: ${userRole}`);

    let permissionCheck = '';
    let checkParams = [requestId];

    if (userRole === 'seeker') {
      permissionCheck = 'AND sr.seeker_id = $2';
      checkParams.push(userId);
    } else if (userRole === 'provider') {
      // First get the provider profile ID for this user
      const providerResult = await query(
        'SELECT id FROM provider_profiles WHERE user_id = $1',
        [userId]
      );

      if (providerResult.rows.length === 0) {
        console.log('Provider profile not found for user:', userId);
        return res.status(403).json({
          success: false,
          message: 'Provider profile not found'
        });
      }

      const providerId = providerResult.rows[0].id;
      console.log(`Provider ID: ${providerId}`);
      
      permissionCheck = 'AND sr.provider_id = $2';
      checkParams.push(providerId);
    } else if (userRole !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    console.log(`Permission check: ${permissionCheck}`);
    console.log(`Check params:`, checkParams);

    // Get request with full details - simplified query first
    const result = await query(
      `SELECT sr.*, 
              s.title as service_title, s.description as service_description, 
              s.price as service_price, s.duration_hours,
              pp.business_name as provider_business_name, pp.location as provider_location,
              pp.provider_type, pp.phone as provider_phone,
              u_seeker.name as seeker_name, u_seeker.email as seeker_email,
              u_provider.name as provider_name, u_provider.email as provider_email,
              e.employee_name as employee_name, e.phone as employee_phone, e.email as employee_email,
              e.role as employee_position
       FROM service_requests sr
       JOIN services s ON sr.service_id = s.id
       JOIN provider_profiles pp ON sr.provider_id = pp.id
       JOIN users u_seeker ON sr.seeker_id = u_seeker.id
       JOIN users u_provider ON pp.user_id = u_provider.id
       LEFT JOIN employees e ON sr.assigned_employee_id = e.id
       WHERE sr.id = $1 ${permissionCheck}`,
      checkParams
    );

    console.log(`Query result rows: ${result.rows.length}`);

    if (result.rows.length === 0) {
      console.log('No request found with given ID and permissions');
      return res.status(404).json({
        success: false,
        message: 'Service request not found or access denied'
      });
    }

    const request = result.rows[0];
    console.log(`Found request: ${request.id}, Status: ${request.status}`);

    // Format the response with proper data structure
    const formattedRequest = {
      id: request.id,
      seekerId: request.seeker_id,
      serviceId: request.service_id,
      providerId: request.provider_id,
      assignedEmployeeId: request.assigned_employee_id,
      status: request.status,
      requestedDate: request.requested_date,
      scheduledDate: request.scheduled_date,
      completionDate: request.completion_date,
      notes: request.notes,
      seekerRating: request.seeker_rating,
      seekerReview: request.seeker_review,
      providerRating: request.provider_rating,
      providerReview: request.provider_review,
      employeeRating: request.employee_rating,
      employeeReview: request.employee_review,
      urgency: request.urgency || 'medium',
      estimatedCompletionDate: request.estimated_completion_date,
      actualCompletionDate: request.actual_completion_date,
      notificationsEnabled: request.notifications_enabled !== false,
      service: {
        id: request.service_id,
        title: request.service_title || 'Unknown Service',
        description: request.service_description,
        price: parseFloat(request.service_price || 0),
        durationHours: request.duration_hours || 0,
      },
      seeker: {
        id: request.seeker_id,
        name: request.seeker_name || 'Unknown Seeker',
        email: request.seeker_email,
      },
      provider: {
        id: request.provider_id,
        businessName: request.provider_business_name,
        location: request.provider_location,
        providerType: request.provider_type,
        phone: request.provider_phone,
        name: request.provider_name || 'Unknown Provider',
        email: request.provider_email,
      },
      assignedEmployee: request.employee_name ? {
        id: request.assigned_employee_id,
        name: request.employee_name,
        position: request.employee_position,
        phone: request.employee_phone,
        email: request.employee_email,
      } : null,
      createdAt: request.created_at,
      updatedAt: request.updated_at,
    };

    console.log('Sending formatted request response');
    res.json({
      success: true,
      message: 'Request details retrieved successfully',
      request: formattedRequest
    });

  } catch (error) {
    console.error('Get service request details error:', error);
    console.error('Error stack:', error.stack);
    res.status(500).json({
      success: false,
      message: 'Internal server error while retrieving request details',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Add rating and review
const addRatingAndReview = async (req, res) => {
  try {
    const userId = req.user.id;
    const { requestId } = req.params;
    const { rating, review } = req.body;

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
    acceptServiceRequest, addRatingAndReview, assignEmployee, cancelServiceRequest, completeServiceRequest, createServiceRequest, getServiceRequestDetails, getServiceRequests, rejectServiceRequest,
    startServiceRequest, updateServiceRequestStatus
};

