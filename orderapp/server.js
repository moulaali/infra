// Import dependencies
const express = require('express');
const bodyParser = require('body-parser');
const orderService = require('./backend/orderService');

// Create an Express app
const app = express();
app.set('view engine', 'ejs');
const port = 3000;

// Middleware to parse JSON request bodies
app.use(bodyParser.json());

// Create a new order (Create)
app.post('/create-order', async (req, res) => {
  try {
    const { customer_name, product, quantity } = req.body;
    const orderId = await orderService.createOrder(customer_name, product, quantity);
    res.redirect('/orders');  // Redirect to orders page after successful creation
  } catch (error) {
    res.status(500).send('Failed to create order');
  }
});

// Update an existing order (Update)
app.post('/update-order', async (req, res) => {
  try {
    const { id, customer_name, product, quantity } = req.body;
    const affectedRows = await orderService.updateOrder(id, customer_name, product, quantity);
    if (affectedRows === 0) {
      return res.status(404).send('Order not found');
    }
    res.redirect('/orders');  // Redirect to orders page after successful update
  } catch (error) {
    res.status(500).send('Failed to update order');
  }
});

// Delete an order (Delete)
app.post('/delete-order', async (req, res) => {
  try {
    const { id } = req.body;
    const affectedRows = await orderService.deleteOrder(id);
    if (affectedRows === 0) {
      return res.status(404).send('Order not found');
    }
    res.redirect('/orders');  // Redirect to orders page after successful deletion
  } catch (error) {
    res.status(500).send('Failed to delete order');
  }
});

app.get('/index', (req, res) => {
  res.render('index');
});


// Start the server
app.listen(port, () => {
  console.log(`Order Server is running on port ${port}`);
});
