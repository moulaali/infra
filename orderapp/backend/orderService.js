// Import the MySQL connection pool
const mysql = require('mysql2');

// Create a MySQL connection pool
const pool = mysql.createPool({
  host: 'localhost', // Replace with your DB host
  user: 'root',      // Replace with your DB user
  password: 'mysql', // Replace with your DB password
  database: 'order_db', // Replace with your DB name
});

// CRUD methods

// Get all orders
const getAllOrders = () => {
  return new Promise((resolve, reject) => {
    pool.query('SELECT * FROM orders', (err, results) => {
      if (err) {
        return reject(err);
      }
      resolve(results);
    });
  });
};

// Get order by ID
const getOrderById = (id) => {
  return new Promise((resolve, reject) => {
    pool.query('SELECT * FROM orders WHERE id = ?', [id], (err, results) => {
      if (err) {
        return reject(err);
      }
      if (results.length === 0) {
        return resolve(null);
      }
      resolve(results[0]);
    });
  });
};

// Create a new order
const createOrder = (customer_name, product, quantity, price) => {
 console.log("Inserting into orders tables", customer_name, product, quantity, price)
  return new Promise((resolve, reject) => {
    pool.query(
      'INSERT INTO orders (customer_name, product, quantity, price) VALUES (?, ?, ?, ?)',
      [customer_name, product, quantity, price],
      (err, results) => {
        if (err) {
          console.log("Error inserting new order", err)
          return reject(err);
        }
        console.log("Successfully created new order with id", results.insertId)
        resolve(results.insertId);
      }
    );
  });
};

// Update an order by ID
const updateOrder = (id, customer_name, product, quantity) => {
  return new Promise((resolve, reject) => {
    pool.query(
      'UPDATE orders SET customer_name = ?, product = ?, quantity = ? WHERE id = ?',
      [customer_name, product, quantity, id],
      (err, results) => {
        if (err) {
          return reject(err);
        }
        resolve(results.affectedRows);
      }
    );
  });
};

// Delete an order by ID
const deleteOrder = (id) => {
  return new Promise((resolve, reject) => {
    pool.query('DELETE FROM orders WHERE id = ?', [id], (err, results) => {
      if (err) {
        return reject(err);
      }
      resolve(results.affectedRows);
    });
  });
};

module.exports = {
  getAllOrders,
  getOrderById,
  createOrder,
  updateOrder,
  deleteOrder
};
