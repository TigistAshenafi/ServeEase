import { query } from '../config/database.js';

// Get all employees for an organization
const getEmployees = async (req, res) => {
  try {
    const userId = req.user.id;

    // Get organization profile ID
    const orgResult = await query(
      'SELECT id FROM provider_profiles WHERE user_id = $1 AND provider_type = $2',
      [userId, 'organization']
    );

    if (orgResult.rows.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'Access denied. Only organizations can manage employees.'
      });
    }

    const organizationId = orgResult.rows[0].id;

    const result = await query(
      `SELECT e.*, u.name as user_name, u.email as user_email
       FROM employees e
       LEFT JOIN users u ON e.user_id = u.id
       WHERE e.organization_id = $1
       ORDER BY e.created_at DESC`,
      [organizationId]
    );

    res.json({
      success: true,
      employees: result.rows.map(employee => ({
        id: employee.id,
        organizationId: employee.organization_id,
        userId: employee.user_id,
        employeeName: employee.employee_name,
        email: employee.email,
        phone: employee.phone,
        role: employee.role,
        skills: employee.skills,
        isActive: employee.is_active,
        hireDate: employee.hire_date,
        documents: employee.documents,
        user: employee.user_id ? {
          name: employee.user_name,
          email: employee.user_email
        } : null,
        createdAt: employee.created_at,
        updatedAt: employee.updated_at
      }))
    });

  } catch (error) {
    console.error('Get employees error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Add new employee
const addEmployee = async (req, res) => {
  try {
    const userId = req.user.id;
    const {
      employeeName,
      email,
      phone,
      role,
      skills,
      hireDate,
      documents
    } = req.body;

    // Validate required fields
    if (!employeeName || !email || !role) {
      return res.status(400).json({
        success: false,
        message: 'Employee name, email, and role are required'
      });
    }

    // Get organization profile ID
    const orgResult = await query(
      'SELECT id FROM provider_profiles WHERE user_id = $1 AND provider_type = $2',
      [userId, 'organization']
    );

    if (orgResult.rows.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'Access denied. Only organizations can add employees.'
      });
    }

    const organizationId = orgResult.rows[0].id;

    // Check if employee with this email already exists in the organization
    const existingEmployee = await query(
      'SELECT id FROM employees WHERE organization_id = $1 AND email = $2',
      [organizationId, email]
    );

    if (existingEmployee.rows.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'An employee with this email already exists in your organization'
      });
    }

    // Check if there's a user account with this email
    const userResult = await query('SELECT id FROM users WHERE email = $1', [email]);
    const employeeUserId = userResult.rows.length > 0 ? userResult.rows[0].id : null;

    // Add employee
    const result = await query(
      `INSERT INTO employees (organization_id, user_id, employee_name, email, phone, role, skills, hire_date, documents)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       RETURNING *`,
      [
        organizationId,
        employeeUserId,
        employeeName,
        email,
        phone,
        role,
        skills || [],
        hireDate,
        JSON.stringify(documents || [])
      ]
    );

    const employee = result.rows[0];

    res.status(201).json({
      success: true,
      message: 'Employee added successfully',
      employee: {
        id: employee.id,
        organizationId: employee.organization_id,
        userId: employee.user_id,
        employeeName: employee.employee_name,
        email: employee.email,
        phone: employee.phone,
        role: employee.role,
        skills: employee.skills,
        isActive: employee.is_active,
        hireDate: employee.hire_date,
        documents: employee.documents,
        createdAt: employee.created_at,
        updatedAt: employee.updated_at
      }
    });

  } catch (error) {
    console.error('Add employee error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Update employee
const updateEmployee = async (req, res) => {
  try {
    const userId = req.user.id;
    const { employeeId } = req.params;
    const {
      employeeName,
      email,
      phone,
      role,
      skills,
      isActive,
      hireDate,
      documents
    } = req.body;

    // Get organization profile ID
    const orgResult = await query(
      'SELECT id FROM provider_profiles WHERE user_id = $1 AND provider_type = $2',
      [userId, 'organization']
    );

    if (orgResult.rows.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'Access denied. Only organizations can update employees.'
      });
    }

    const organizationId = orgResult.rows[0].id;

    // Check if employee belongs to this organization
    const employeeResult = await query(
      'SELECT id FROM employees WHERE id = $1 AND organization_id = $2',
      [employeeId, organizationId]
    );

    if (employeeResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Employee not found or access denied'
      });
    }

    // Check if new email conflicts with existing employees
    if (email) {
      const emailConflict = await query(
        'SELECT id FROM employees WHERE organization_id = $1 AND email = $2 AND id != $3',
        [organizationId, email, employeeId]
      );

      if (emailConflict.rows.length > 0) {
        return res.status(400).json({
          success: false,
          message: 'Another employee with this email already exists'
        });
      }
    }

    // Update employee
    const result = await query(
      `UPDATE employees
       SET employee_name = $1, email = $2, phone = $3, role = $4, skills = $5, is_active = $6, hire_date = $7, documents = $8, updated_at = NOW()
       WHERE id = $9 AND organization_id = $10
       RETURNING *`,
      [
        employeeName,
        email,
        phone,
        role,
        skills || [],
        isActive !== undefined ? isActive : true,
        hireDate,
        JSON.stringify(documents || []),
        employeeId,
        organizationId
      ]
    );

    const employee = result.rows[0];

    res.json({
      success: true,
      message: 'Employee updated successfully',
      employee: {
        id: employee.id,
        organizationId: employee.organization_id,
        userId: employee.user_id,
        employeeName: employee.employee_name,
        email: employee.email,
        phone: employee.phone,
        role: employee.role,
        skills: employee.skills,
        isActive: employee.is_active,
        hireDate: employee.hire_date,
        documents: employee.documents,
        createdAt: employee.created_at,
        updatedAt: employee.updated_at
      }
    });

  } catch (error) {
    console.error('Update employee error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Remove employee
const removeEmployee = async (req, res) => {
  try {
    const userId = req.user.id;
    const { employeeId } = req.params;

    // Get organization profile ID
    const orgResult = await query(
      'SELECT id FROM provider_profiles WHERE user_id = $1 AND provider_type = $2',
      [userId, 'organization']
    );

    if (orgResult.rows.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'Access denied. Only organizations can remove employees.'
      });
    }

    const organizationId = orgResult.rows[0].id;

    // Soft delete employee
    const result = await query(
      'UPDATE employees SET is_active = false, updated_at = NOW() WHERE id = $1 AND organization_id = $2',
      [employeeId, organizationId]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({
        success: false,
        message: 'Employee not found or access denied'
      });
    }

    res.json({
      success: true,
      message: 'Employee removed successfully'
    });

  } catch (error) {
    console.error('Remove employee error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Get available employees for service assignment
const getAvailableEmployees = async (req, res) => {
  try {
    const userId = req.user.id;
    const { serviceId } = req.params;

    // Get organization profile ID
    const orgResult = await query(
      'SELECT id FROM provider_profiles WHERE user_id = $1 AND provider_type = $2',
      [userId, 'organization']
    );

    if (orgResult.rows.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'Access denied. Only organizations can assign employees.'
      });
    }

    const organizationId = orgResult.rows[0].id;

    // Get service details to match employee skills
    const serviceResult = await query(
      'SELECT s.*, sc.name as category_name FROM services s JOIN service_categories sc ON s.category_id = sc.id WHERE s.id = $1 AND s.provider_id = $2',
      [serviceId, organizationId]
    );

    if (serviceResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Service not found'
      });
    }

    const service = serviceResult.rows[0];

    // Get active employees who have relevant skills or role
    const employeesResult = await query(
      `SELECT e.* FROM employees e
       WHERE e.organization_id = $1 AND e.is_active = true
       AND (e.role = $2 OR e.skills @> ARRAY[$2] OR e.role ILIKE '%' || $2 || '%')
       ORDER BY e.employee_name`,
      [organizationId, service.category_name]
    );

    res.json({
      success: true,
      employees: employeesResult.rows.map(employee => ({
        id: employee.id,
        employeeName: employee.employee_name,
        email: employee.email,
        phone: employee.phone,
        role: employee.role,
        skills: employee.skills
      })),
      service: {
        id: service.id,
        title: service.title,
        category: service.category_name
      }
    });

  } catch (error) {
    console.error('Get available employees error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

export {
  getEmployees,
  addEmployee,
  updateEmployee,
  removeEmployee,
  getAvailableEmployees
};
