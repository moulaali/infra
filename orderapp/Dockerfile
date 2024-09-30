# Stage 1: Build the Node.js app
FROM node:18 AS builder

# Set the working directory inside the container
WORKDIR /usr/src/app

# Copy package.json and package-lock.json (if available) to install dependencies
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application code
COPY . .

# Stage 2: Create the runtime image
FROM node:18-alpine AS runtime

# Set the working directory inside the container
WORKDIR /usr/src/app

# Copy only the necessary files from the build stage
COPY --from=builder /usr/src/app .

# Expose the port that the app listens on
EXPOSE 3000

# Set environment variables (optional if required for your app)
ENV NODE_ENV=production

# Start the app
CMD ["node", "server.js"]
