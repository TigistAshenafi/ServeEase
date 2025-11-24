import db from "../config/db.js";

export default {
  async create(provider_id, title, description, price) {
    const result = await db.query(
      `INSERT INTO services (provider_id, title, description, price)
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [provider_id, title, description, price]
    );
    return result.rows[0];
  },

  async findByProvider(provider_id) {
    const result = await db.query(
      `SELECT * FROM services WHERE provider_id = $1`,
      [provider_id]
    );
    return result.rows;
  },

  async delete(service_id) {
    await db.query(
      `DELETE FROM services WHERE id=$1`,
      [service_id]
    );
  }
};
