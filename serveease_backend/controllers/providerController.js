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

// Create or update provider profile
const createOrUpdateProfile = async (req, res) => {
  try {
    const userId = req.user.id;
    const {
      providerType,
      businessName,
      description,
      category,
      location,
      phone,
      certificates // For individual providers
    } = req.body;

    // Validate provider type
    if (!['individual', 'organization'].includes(providerType)) {
      return res.status(400).json({
        success: false,
        message: 'Provider type must be either individual or organization'
      });
    }

    // For individual providers, certificates are required
    if (providerType === 'individual' && (!certificates || certificates.length === 0)) {
      return res.status(400).json({
        success: false,
        message: 'Individual providers must upload at least one certificate'
      });
    }

    // Check if profile already exists
    const existingProfile = await query(
      'SELECT id FROM provider_profiles WHERE user_id = $1',
      [userId]
    );

    let result;
    if (existingProfile.rows.length > 0) {
      // Update existing profile
      result = await query(
        `UPDATE provider_profiles
         SET provider_type = $1, business_name = $2, description = $3, category = $4, location = $5, phone = $6, certificates = $7, updated_at = NOW()
         WHERE user_id = $8
         RETURNING *`,
        [providerType, businessName, description, category, location, phone, JSON.stringify(certificates || []), userId]
      );
    } else {
      // Create new profile
      result = await query(
        `INSERT INTO provider_profiles (user_id, provider_type, business_name, description, category, location, phone, certificates)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         RETURNING *`,
        [userId, providerType, businessName, description, category, location, phone, JSON.stringify(certificates || [])]
      );
    }

    const profile = result.rows[0];

    res.json({
      success: true,
      message: 'Provider profile saved successfully',
      profile: {
        id: profile.id,
        providerType: profile.provider_type,
        businessName: profile.business_name,
        description: profile.description,
        category: profile.category,
        location: profile.location,
        phone: profile.phone,
        certificates: profile.certificates,
        isApproved: profile.is_approved,
        createdAt: profile.created_at,
        updatedAt: profile.updated_at
      }
    });

  } catch (error) {
    console.error('Create/update profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Get provider profile
const getProfile = async (req, res) => {
  try {
    const userId = req.user.id;

    const result = await query(
      `SELECT pp.*, u.name, u.email
       FROM provider_profiles pp
       JOIN users u ON pp.user_id = u.id
       WHERE pp.user_id = $1`,
      [userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Provider profile not found'
      });
    }

    const profile = result.rows[0];

    res.json({
      success: true,
      profile: {
        id: profile.id,
        userId: profile.user_id,
        providerType: profile.provider_type,
        businessName: profile.business_name,
        description: profile.description,
        category: profile.category,
        location: profile.location,
        phone: profile.phone,
        profileImageUrl: profile.profile_image_url,
        documents: profile.documents,
        certificates: profile.certificates,
        status: profile.status,
        isApproved: profile.is_approved,
        approvalDate: profile.approval_date,
        adminNotes: profile.admin_notes,
        user: {
          name: profile.name,
          email: profile.email
        },
        createdAt: profile.created_at,
        updatedAt: profile.updated_at
      }
    });

  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Get all providers (for admin)
const getAllProviders = async (req, res) => {
  try {
    const { status = 'all', page = 1, limit = 10 } = req.query;
    const offset = (page - 1) * limit;

    let whereClause = '';
    let params = [limit, offset];

    if (status === 'pending') {
      whereClause = 'WHERE pp.status = \'pending\'';
    } else if (status === 'approved') {
      whereClause = 'WHERE pp.status = \'approved\'';
    } else if (status === 'rejected') {
      whereClause = 'WHERE pp.status = \'rejected\'';
    }

    const result = await query(
      `SELECT pp.*, u.name, u.email, u.created_at as user_created_at
       FROM provider_profiles pp
       JOIN users u ON pp.user_id = u.id
       ${whereClause}
       ORDER BY pp.created_at DESC
       LIMIT $1 OFFSET $2`,
      params
    );

    // Get total count
    const countResult = await query(
      `SELECT COUNT(*) as total FROM provider_profiles pp ${whereClause}`,
      status === 'all' ? [] : []
    );

    const total = parseInt(countResult.rows[0].total);

    res.json({
      success: true,
      providers: result.rows.map(provider => ({
        id: provider.id,
        userId: provider.user_id,
        businessName: provider.business_name,
        description: provider.description,
        category: provider.category,
        location: provider.location,
        phone: provider.phone,
        status: provider.status,
        isApproved: provider.is_approved,
        approvalDate: provider.approval_date,
        adminNotes: provider.admin_notes,
        user: {
          name: provider.name,
          email: provider.email,
          createdAt: provider.user_created_at
        },
        createdAt: provider.created_at
      })),
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });

  } catch (error) {
    console.error('Get all providers error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Approve provider
const approveProvider = async (req, res) => {
  try {
    const { providerId } = req.params;
    const { adminNotes } = req.body;

    const result = await query(
      `UPDATE provider_profiles
       SET status = 'approved', is_approved = true, approval_date = NOW(), admin_notes = $1, updated_at = NOW()
       WHERE id = $2
       RETURNING *`,
      [adminNotes, providerId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Provider not found'
      });
    }

    const profile = result.rows[0];

    // Send approval email
    try {
      const userResult = await query('SELECT name, email FROM users WHERE id = $1', [profile.user_id]);
      const user = userResult.rows[0];

      await transporter.sendMail({
        from: process.env.EMAIL_FROM,
        to: user.email,
        subject: 'Your ServeEase Provider Account Has Been Approved!',
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h2>Congratulations, ${user.name}!</h2>
            <p>Your provider account has been approved. You can now offer services on ServeEase.</p>
            <p>You can start creating your service listings and accepting requests from seekers.</p>
            ${adminNotes ? `<p><strong>Admin Notes:</strong> ${adminNotes}</p>` : ''}
            <p>Best regards,<br>The ServeEase Team</p>
          </div>
        `,
      });
    } catch (emailError) {
      console.error('Approval email sending failed:', emailError);
    }

    res.json({
      success: true,
      message: 'Provider approved successfully',
      profile: {
        id: profile.id,
        isApproved: true,
        approvalDate: profile.approval_date,
        adminNotes: profile.admin_notes
      }
    });

  } catch (error) {
    console.error('Approve provider error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Reject provider
const rejectProvider = async (req, res) => {
  try {
    const { providerId } = req.params;
    const { adminNotes } = req.body;

    const result = await query(
      `UPDATE provider_profiles
       SET status = 'rejected', is_approved = false, admin_notes = $1, updated_at = NOW()
       WHERE id = $2
       RETURNING *`,
      [adminNotes, providerId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Provider not found'
      });
    }

    const profile = result.rows[0];

    // Send rejection email
    try {
      const userResult = await query('SELECT name, email FROM users WHERE id = $1', [profile.user_id]);
      const user = userResult.rows[0];

      await transporter.sendMail({
        from: process.env.EMAIL_FROM,
        to: user.email,
        subject: 'ServeEase Provider Application Update',
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h2>Hello, ${user.name}</h2>
            <p>We regret to inform you that your provider application has been rejected.</p>
            ${adminNotes ? `<p><strong>Reason:</strong> ${adminNotes}</p>` : ''}
            <p>You can update your profile and reapply for approval.</p>
            <p>Best regards,<br>The ServeEase Team</p>
          </div>
        `,
      });
    } catch (emailError) {
      console.error('Rejection email sending failed:', emailError);
    }

    res.json({
      success: true,
      message: 'Provider rejected',
      profile: {
        id: profile.id,
        isApproved: false,
        adminNotes: profile.admin_notes
      }
    });

  } catch (error) {
    console.error('Reject provider error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

export {
    approveProvider, createOrUpdateProfile, getAllProviders, getProfile, rejectProvider
};

