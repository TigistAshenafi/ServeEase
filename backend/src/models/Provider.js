import db from "../config/db.js";

export default {
  async create(user_id, business_name, description) {
    const result = await db.query(
      `INSERT INTO providers (user_id, business_name, description, status)
       VALUES ($1, $2, $3, 'pending') RETURNING *`,
      [user_id, business_name, description]
    );
    return result.rows[0];
  },

  async findByUserId(user_id) {
    const result = await db.query(
      `SELECT * FROM providers WHERE user_id = $1`,
      [user_id]
    );
    return result.rows[0];
  },

  async findAll() {
    const result = await db.query(`SELECT * FROM providers ORDER BY created_at DESC`);
    return result.rows;
  },

  async updateStatus(id, status) {
    const result = await db.query(
      `UPDATE providers SET status=$1, updated_at=NOW() WHERE id=$2 RETURNING *`,
      [status, id]
    );
    return result.rows[0];
  }
};
