const express = require('express');
const path = require('path');

const app = express();
const port = 3000;

// Set view engine to ejs
app.set('view engine', 'ejs');

// Serve static files from the "public" directory
app.use(express.static(path.join(__dirname, 'public')));

// Routes
app.get('/', (req, res) => {
  res.render('index');
});

// Start the server
app.listen(port, () => {
  console.log(`App running on http://localhost:${port}`);
});
