import db from "../config/db.js";

export default {
  // ----------------- CREATE PROVIDER PROFILE -----------------
  async create(user_id, profileData, client = null) {
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
    } = profileData;

    if (!business_name?.trim() || !description?.trim()) {
      throw new Error("Business name and description are required.");
    }

    const query = `
      INSERT INTO provider_profiles (
        user_id, business_name, description, category, experience, location,
        price, profile_image, certificates, availability, status, created_at, updated_at
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,'pending', NOW(), NOW())
      RETURNING *
    `;

    const values = [
      user_id,
      business_name.trim(),
      description.trim(),
      category || null,
      experience || null,
      location || null,
      price || null,
      profile_image || null,
      certificates ? JSON.stringify(certificates) : null,
      availability ? JSON.stringify(availability) : null
    ];

    const dbClient = client || db;
    const result = await dbClient.query(query, values);
    return result.rows[0];
  },

  // ----------------- FIND BY USER ID -----------------
  async findByUserId(user_id) {
    const result = await db.query(
      `SELECT * FROM provider_profiles WHERE user_id = $1`,
      [user_id]
    );
    return result.rows[0];
  },

  // ----------------- GET ALL PROVIDERS -----------------
  async findAll({ status, category, limit = 50, offset = 0 } = {}) {
    let query = `SELECT * FROM provider_profiles WHERE 1=1`;
    const params = [];
    let idx = 1;

    if (status) {
      query += ` AND status=$${idx++}`;
      params.push(status);
    }
    if (category) {
      query += ` AND category=$${idx++}`;
      params.push(category);
    }

    query += ` ORDER BY created_at DESC LIMIT $${idx++} OFFSET $${idx++}`;
    params.push(limit, offset);

    const result = await db.query(query, params);
    return result.rows;
  },

  // ----------------- UPDATE PROVIDER STATUS -----------------
  async updateStatus(id, status) {
    if (!["pending", "approved", "rejected"].includes(status)) {
      throw new Error("Invalid status value.");
    }

    const result = await db.query(
      `UPDATE provider_profiles 
       SET status=$1, updated_at=NOW() 
       WHERE id=$2 
       RETURNING *`,
      [status, id]
    );

    return result.rows[0];
  },

  // ----------------- OPTIONAL: UPDATE PROFILE -----------------
  async updateProfile(user_id, profileData) {
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
    } = profileData;

    const query = `
      UPDATE provider_profiles
      SET
        business_name = COALESCE($1, business_name),
        description = COALESCE($2, description),
        category = COALESCE($3, category),
        experience = COALESCE($4, experience),
        location = COALESCE($5, location),
        price = COALESCE($6, price),
        profile_image = COALESCE($7, profile_image),
        certificates = COALESCE($8, certificates),
        availability = COALESCE($9, availability),
        updated_at = NOW()
      WHERE user_id = $10
      RETURNING *
    `;

    const values = [
      business_name?.trim() || null,
      description?.trim() || null,
      category || null,
      experience || null,
      location || null,
      price || null,
      profile_image || null,
      certificates ? JSON.stringify(certificates) : null,
      availability ? JSON.stringify(availability) : null,
      user_id
    ];

    const result = await db.query(query, values);
    return result.rows[0];
  }
};
