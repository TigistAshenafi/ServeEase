import Provider from "../models/Provider.js";

/**
 * Standard API response
 */
const sendResponse = (res, status, success, message, data = null) => {
  res.status(status).json({ success, message, data });
};

export const createProviderProfile = async (req, res, next) => {
  try {
    const userId = req.user.userId; // from auth middleware

    // Ensure user exists, is verified and has role = provider
    const u = await pool.query('SELECT role, is_verified FROM users WHERE id=$1', [userId]);
    if (!u.rows.length) return sendResponse(res, 404, false, 'User not found.');

    const user = u.rows[0];
    if (!user.is_verified) return sendResponse(res, 403, false, 'Verify email before creating provider profile.');
    if (user.role !== 'provider') return sendResponse(res, 403, false, 'Only providers can create a provider profile.');

    const {
      business_name,
      description,
      category,
      experience,
      location,
      price,
      profile_image,
      certificates,
      availability
    } = req.body;

    if (!business_name?.trim() || !description?.trim()) {
      return sendResponse(res, 400, false, "Business name and description are required.");
    }

    // check existing
    const existing = await Provider.findByUserId(userId);
    if (existing) {
      return sendResponse(res, 400, false, "Provider profile already exists.");
    }

    // create profile
    const profile = await Provider.create(userId, {
      business_name: business_name.trim(),
      description: description.trim(),
      category,
      experience,
      location,
      price,
      profile_image,
      certificates,
      availability
    });

    return sendResponse(res, 201, true, "Provider profile created successfully.", profile);
  } catch (err) {
    next(err);
  }
};

export const getProviderProfile = async (req, res, next) => {
  try {
    const userId = req.user.userId;
    const profile = await Provider.findByUserId(userId);

    if (!profile) {
      return sendResponse(res, 404, false, "Provider profile not found.");
    }

    return sendResponse(res, 200, true, "Provider profile fetched.", profile);
  } catch (err) {
    next(err);
  }
};

// ------------------- GET ALL PROVIDERS -------------------
export const getAllProviders = async (req, res, next) => {
  try {
    // Optional query params: status, category, limit, page
    const { status, category, limit = 20, page = 1 } = req.query;
    const offset = (page - 1) * limit;

    const filters = {};
    if (status) filters.status = status;
    if (category) filters.category = category;

    const providers = await Provider.findAll(filters, limit, offset);
    return sendResponse(res, 200, true, "Providers fetched.", providers);
  } catch (err) {
    next(err);
  }
};

// ------------------- UPDATE PROVIDER STATUS (ADMIN ONLY) -------------------
export const updateProviderStatus = async (req, res, next) => {
  try {
    const adminRole = req.user.role;
    if (adminRole !== "admin") {
      return sendResponse(res, 403, false, "Unauthorized. Admin access required.");
    }

    const { id } = req.params;
    const { status } = req.body;

    if (!["pending", "approved", "rejected"].includes(status)) {
      return sendResponse(res, 400, false, "Invalid status value.");
    }

    const updatedProfile = await Provider.updateStatus(id, status);
    if (!updatedProfile) {
      return sendResponse(res, 404, false, "Provider profile not found.");
    }

    // Optional: log status change
    // console.log(`Provider ${id} status changed to ${status} by admin ${req.user.userId}`);

    return sendResponse(res, 200, true, `Provider status updated to '${status}'.`, updatedProfile);
  } catch (err) {
    next(err);
  }
};
