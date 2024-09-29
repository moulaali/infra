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
app.use(express.urlencoded({ extended: true }));  // To parse URL-encoded form data
app.use(express.json());  // To parse JSON body

// Create a new order (Create)
app.post('/create-order', async (req, res) => {
  try {
    console.log("POST:create-order : ", req.body)
    const { customer_name, product, quantity, price } = req.body;
    const orderId = await orderService.createOrder(customer_name, product, quantity, price);
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
  res.redirect('orders');
});

app.get('/', (req, res) => {
  res.redirect('orders');
});

app.get('/create-order', (req, res) => {
  res.render('createOrder');
});

app.get('/orders', async (req, res) => {
    try {

        const result = await orderService.getAllOrders();
        const orders = Array.isArray(result) ? result : [result];
        res.render('orders', { orders: orders})
      } catch (error) {
        res.status(500).send('Unable to fetch orders : ' + error);
      }
});


// Start the server
app.listen(port, () => {
  console.log(`Order Server is running on port ${port}`);
});
