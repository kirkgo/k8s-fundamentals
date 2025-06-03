# Kubernetes Final Project
## Building a Full-Stack Todo Application with Kubernetes

We'll deploy a complete web application that demonstrates all the core Kubernetes concepts. By the end of this workshop, you'll have built and deployed a production-ready application using Docker Desktop's Kubernetes.

### Project Overview
We'll build and deploy a **Todo Application** with:

- **Frontend**: React web application
- **Backend**: Node.js REST API
- **Database**: MongoDB
- **All running in Kubernetes with proper configurations**

### What We'll Cover
- Docker Images creation
- Deployments
- Services (ClusterIP, NodePort)
- ConfigMaps
- Database deployment
- Logs monitoring

---

## Prerequisites

### Enable Kubernetes in Docker Desktop
1. Open Docker Desktop
2. Go to Settings → Kubernetes
3. Check "Enable Kubernetes"
4. Click "Apply & Restart"
5. Wait for the green indicator

### Verify Installation
```bash
kubectl version --client
kubectl cluster-info
```

---

## 📁 Project Structure
Our project structure:

```
009-result-final-project/
├── frontend/
│   ├── public/
│   │   └── index.html
│   ├── src/
│   │   ├── App.js
│   │   ├── App.css
│   │   ├── index.js
│   │   └── index.css
│   ├── .env
│   ├── Dockerfile
│   ├── nginx.conf
│   └── package.json
├── backend/
│   ├── Dockerfile
│   ├── package.json
│   └── server.js
└── k8s/
    ├── namespace.yaml
    ├── configmap.yaml
    ├── mongodb-deployment.yaml
    ├── backend-deployment.yaml
    └── frontend-deployment.yaml
```

---

## Step 1: Creating Docker Images

### Backend Application (Node.js API)

First, create our backend API:

**backend/package.json:**
```json
{
  "name": "todo-backend",
  "version": "1.0.0",
  "main": "server.js",
  "dependencies": {
    "express": "^4.18.2",
    "mongoose": "^7.5.0",
    "cors": "^2.8.5"
  }
}
```

**backend/server.js:**
```javascript
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 5000;
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/todoapp';

// Enable CORS for all origins (for demo purposes)
app.use(cors({
  origin: true,
  credentials: true
}));

app.use(express.json());

// Connect to MongoDB
mongoose.connect(MONGODB_URI)
  .then(() => console.log('Connected to MongoDB'))
  .catch(err => console.error('MongoDB connection error:', err));

// Todo Schema
const todoSchema = new mongoose.Schema({
  text: { type: String, required: true },
  completed: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now }
});

const Todo = mongoose.model('Todo', todoSchema);

// Add request logging
app.use((req, res, next) => {
  console.log(`${req.method} ${req.path}`, req.body);
  next();
});

// Routes
app.get('/api/todos', async (req, res) => {
  try {
    const todos = await Todo.find().sort({ createdAt: -1 });
    console.log('Fetched todos:', todos.length);
    res.json(todos);
  } catch (error) {
    console.error('Error fetching todos:', error);
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/todos', async (req, res) => {
  try {
    console.log('Creating todo with text:', req.body.text);
    const todo = new Todo({ text: req.body.text });
    await todo.save();
    console.log('Todo created:', todo);
    res.status(201).json(todo);
  } catch (error) {
    console.error('Error creating todo:', error);
    res.status(400).json({ error: error.message });
  }
});

app.put('/api/todos/:id', async (req, res) => {
  try {
    const todo = await Todo.findByIdAndUpdate(
      req.params.id,
      { completed: req.body.completed },
      { new: true }
    );
    res.json(todo);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

app.delete('/api/todos/:id', async (req, res) => {
  try {
    await Todo.findByIdAndDelete(req.params.id);
    res.status(204).send();
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

**backend/Dockerfile:**
```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package.json .
RUN npm install

COPY . .

EXPOSE 5000

CMD ["node", "server.js"]
```

### Frontend Application (React)

**frontend/package.json:**
```json
{
  "name": "todo-frontend",
  "version": "1.0.0",
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "axios": "^1.4.0"
  },
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build"
  },
  "devDependencies": {
    "react-scripts": "5.0.1"
  },
  "browserslist": {
    "production": [
      ">0.2%",
      "not dead",
      "not op_mini all"
    ],
    "development": [
      "last 1 chrome version",
      "last 1 firefox version",
      "last 1 safari version"
    ]
  }
}
```

**frontend/public/index.html:**
```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="theme-color" content="#000000" />
    <meta name="description" content="Kubernetes Todo App" />
    <title>Kubernetes Todo App</title>
  </head>
  <body>
    <noscript>You need to enable JavaScript to run this app.</noscript>
    <div id="root"></div>
  </body>
</html>
```

**frontend/src/index.js:**
```javascript
import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';
import App from './App';

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
```

**frontend/src/index.css:**
```css
body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
    sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

code {
  font-family: source-code-pro, Menlo, Monaco, Consolas, 'Courier New',
    monospace;
}
```

**frontend/src/App.css:**
```css
.App {
  text-align: center;
}

.App-header {
  background-color: #282c34;
  padding: 20px;
  color: white;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: flex-start;
}

.todo-form {
  margin: 20px 0;
  display: flex;
  gap: 10px;
}

.todo-input {
  padding: 10px;
  font-size: 16px;
  border: 1px solid #ddd;
  border-radius: 4px;
  width: 300px;
}

.add-button {
  padding: 10px 20px;
  font-size: 16px;
  background-color: #61dafb;
  color: #282c34;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.add-button:hover {
  background-color: #21a0c4;
}

.todos-container {
  width: 100%;
  max-width: 500px;
  margin-top: 20px;
}

.todo-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 15px;
  margin: 10px 0;
  background-color: #3a3f47;
  border-radius: 8px;
  cursor: pointer;
}

.todo-item.completed {
  opacity: 0.6;
  text-decoration: line-through;
}

.todo-item span {
  flex-grow: 1;
  text-align: left;
  font-size: 16px;
}

.delete-button {
  background: none;
  border: none;
  cursor: pointer;
  font-size: 16px;
}

.delete-button:hover {
  transform: scale(1.2);
}
```

**frontend/src/App.js:**
```javascript
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './App.css';

const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:30001';

function App() {
    const [todos, setTodos] = useState([]);
    const [newTodo, setNewTodo] = useState('');

    useEffect(() => {
        fetchTodos();
    }, []);

    const fetchTodos = async () => {
        try {
            const response = await axios.get(`${API_URL}/todos`);
            setTodos(response.data);
        } catch (error) {
            console.error('Error fetching todos:', error);
        }
    };

    const addTodo = async (e) => {
        e.preventDefault();
        if (!newTodo.trim()) return;

        try {
            await axios.post(`${API_URL}/todos`, { text: newTodo });
            setNewTodo('');
            fetchTodos();
        } catch (error) {
            console.error('Error adding todo:', error);
        }
    };

    const toggleTodo = async (id, completed) => {
        try {
            await axios.put(`${API_URL}/todos/${id}`, { completed: !completed });
            fetchTodos();
        } catch (error) {
            console.error('Error updating todo:', error);
        }
    };

    const deleteTodo = async (id) => {
        try {
            await axios.delete(`${API_URL}/todos/${id}`);
            fetchTodos();
        } catch (error) {
            console.error('Error deleting todo:', error);
        }
    };

    return (
        <div className="App">
            <header className="App-header">
                <h1>🚀 Kubernetes Todo App</h1>

                <form onSubmit={addTodo} className="todo-form">
                    <input
                        type="text"
                        value={newTodo}
                        onChange={(e) => setNewTodo(e.target.value)}
                        placeholder="Add a new todo..."
                        className="todo-input"
                    />
                    <button type="submit" className="add-button">Add</button>
                </form>

                <div className="todos-container">
                    {todos.map(todo => (
                        <div key={todo._id} className={`todo-item ${todo.completed ? 'completed' : ''}`}>
                            <span onClick={() => toggleTodo(todo._id, todo.completed)}>
                                {todo.text}
                            </span>
                            <button onClick={() => deleteTodo(todo._id)} className="delete-button">
                                ❌
                            </button>
                        </div>
                    ))}
                </div>
            </header>
        </div>
    );
}

export default App;
```

**frontend/.env:**
```env
REACT_APP_API_URL=http://localhost:30001/api
```

**frontend/Dockerfile:**
```dockerfile
FROM node:18-alpine AS builder

WORKDIR /app
COPY package.json .
RUN npm install

COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

**frontend/nginx.conf:**
```nginx
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    server {
        listen 80;
        server_name localhost;
        root /usr/share/nginx/html;
        index index.html;

        location / {
            try_files $uri $uri/ /index.html;
        }
    }
}
```

### Build the Docker Images

```bash
# Navigate to project directory
cd 009-result-final-project

# Build backend image
cd backend
docker build -t todo-backend:v1 .
cd ..

# Build frontend image
cd frontend
docker build -t todo-frontend:v1 .
cd ..
```

**Explanation: Docker Images**

Docker images are the foundation of our Kubernetes deployment. Each image contains our application code, dependencies, and runtime environment. We're using multi-stage builds for the frontend to optimize the final image size.

---

## Step 2: Kubernetes Configuration Files

### Namespace
**k8s/namespace.yaml:**
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: todo-app
  labels:
    name: todo-app
```

**Explanation: Namespaces**

Namespaces provide a way to divide cluster resources between multiple users or applications. It's like having separate folders for different projects.

### ConfigMap
**k8s/configmap.yaml:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: todo-config
  namespace: todo-app
data:
  # Database configuration
  MONGODB_URI: "mongodb://mongodb-service:27017/todoapp"
  
  # Backend configuration
  PORT: "5000"
  NODE_ENV: "production"
  
  # Frontend configuration (not used in React build, but kept for consistency)
  REACT_APP_API_URL: "http://localhost:30001/api"
```

**Explanation: ConfigMaps**

React applications are built as static files, so environment variables must be available during the Docker build process, not at runtime. We use a .env file in the frontend directory to ensure the correct API URL is compiled into the JavaScript bundle. The ConfigMap entry is kept for consistency but doesn't affect the React build.

---

## Step 3: Database Deployment

**k8s/mongodb-deployment.yaml:**
```yaml
# MongoDB Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongodb-deployment
  namespace: todo-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mongodb
  template:
    metadata:
      labels:
        app: mongodb
    spec:
      containers:
      - name: mongodb
        image: mongo:5.0
        ports:
        - containerPort: 27017
        volumeMounts:
        - name: mongodb-storage
          mountPath: /data/db
      volumes:
      - name: mongodb-storage
        emptyDir: {}

---
# MongoDB Service
apiVersion: v1
kind: Service
metadata:
  name: mongodb-service
  namespace: todo-app
spec:
  selector:
    app: mongodb
  ports:
  - protocol: TCP
    port: 27017
    targetPort: 27017
  type: ClusterIP
```

**Explanation: Database Deployment**

We're deploying MongoDB as a single replica with persistent storage. The Service exposes the database internally to other pods in the cluster. ClusterIP means it's only accessible from within the cluster.

---

## Step 4: Backend Deployment

**k8s/backend-deployment.yaml:**
```yaml
# Backend Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-deployment
  namespace: todo-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: todo-backend:v1
        ports:
        - containerPort: 5000
        env:
        - name: MONGODB_URI
          valueFrom:
            configMapKeyRef:
              name: todo-config
              key: MONGODB_URI
        - name: PORT
          valueFrom:
            configMapKeyRef:
              name: todo-config
              key: PORT
        - name: NODE_ENV
          valueFrom:
            configMapKeyRef:
              name: todo-config
              key: NODE_ENV
        livenessProbe:
          httpGet:
            path: /api/todos
            port: 5000
          initialDelaySeconds: 15
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /api/todos
            port: 5000
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3

---
# Backend Service
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: todo-app
spec:
  selector:
    app: backend
  ports:
  - protocol: TCP
    port: 5000
    targetPort: 5000
    nodePort: 30001
  type: NodePort
```

**Explanation: Backend Deployment**

We're running 2 replicas of our backend for high availability. The configuration is injected via ConfigMap. Health checks ensure our pods are healthy. NodePort service exposes the backend externally on port 30001.

---

## Step 5: Frontend Deployment

**k8s/frontend-deployment.yaml:**
```yaml
# Frontend Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-deployment
  namespace: todo-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: todo-frontend:v1
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"

---
# Frontend Service
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: todo-app
spec:
  selector:
    app: frontend
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
    nodePort: 30000
  type: NodePort
```

**Explanation: Frontend Deployment**

The frontend serves static files through Nginx. We're setting resource limits to ensure efficient resource usage. NodePort service makes it accessible on port 30000.

---

## Step 6: Deployment Process

### Apply All Configurations

```bash
# Create namespace first
kubectl apply -f k8s/namespace.yaml

# Apply ConfigMap
kubectl apply -f k8s/configmap.yaml

# Deploy database
kubectl apply -f k8s/mongodb-deployment.yaml

# Wait for MongoDB to be ready
kubectl wait --for=condition=available --timeout=300s deployment/mongodb-deployment -n todo-app

# Deploy backend
kubectl apply -f k8s/backend-deployment.yaml

# Wait for backend to be ready
kubectl wait --for=condition=available --timeout=300s deployment/backend-deployment -n todo-app

# Deploy frontend
kubectl apply -f k8s/frontend-deployment.yaml

# Wait for frontend to be ready
kubectl wait --for=condition=available --timeout=300s deployment/frontend-deployment -n todo-app
```

**Explanation: Deployment Order**

We deploy in a specific order: namespace → configmap → database → backend → frontend. This ensures dependencies are available when each service starts.

---

## Step 7: Monitoring and Logs

### Check Deployment Status
```bash
# View all resources in the namespace
kubectl get all -n todo-app

# Check deployment status
kubectl get deployments -n todo-app

# View pod details
kubectl get pods -n todo-app -o wide

# Describe a specific pod (replace POD_NAME)
kubectl describe pod POD_NAME -n todo-app
```

### Viewing Logs
```bash
# View backend logs
kubectl logs -l app=backend -n todo-app --tail=50

# View frontend logs
kubectl logs -l app=frontend -n todo-app --tail=50

# View MongoDB logs
kubectl logs -l app=mongodb -n todo-app --tail=50

# Follow logs in real-time
kubectl logs -f deployment/backend-deployment -n todo-app

# View logs from all containers with a specific label
kubectl logs -l app=backend -n todo-app --all-containers=true
```

**Explanation: Logs**

Kubernetes aggregates logs from all containers. The `-l` flag uses label selectors to filter pods. The `--tail` flag limits output, and `-f` follows logs in real-time.

### Troubleshooting Commands
```bash
# Check if services are accessible
kubectl port-forward service/backend-service 8080:5000 -n todo-app

# Access a pod directly
kubectl exec -it POD_NAME -n todo-app -- /bin/sh

# Check service endpoints
kubectl get endpoints -n todo-app

# View events
kubectl get events -n todo-app --sort-by='.lastTimestamp'
```

---

## Step 8: Testing the Application

### Access the Application
1. **Frontend**: http://localhost:30000
2. **Backend API**: http://localhost:30001/api/todos

### Test the API Directly
```bash
# Create a todo
curl -X POST http://localhost:30001/api/todos \
  -H "Content-Type: application/json" \
  -d '{"text":"Learn Kubernetes!"}'

# Get all todos
curl http://localhost:30001/api/todos

# Update a todo (replace ID)
curl -X PUT http://localhost:30001/api/todos/TODO_ID \
  -H "Content-Type: application/json" \
  -d '{"completed":true}'
```

---

## Step 9: Scaling and Updates

### Scaling Applications
```bash
# Scale backend to 3 replicas
kubectl scale deployment backend-deployment --replicas=3 -n todo-app

# Scale frontend to 1 replica
kubectl scale deployment frontend-deployment --replicas=1 -n todo-app

# Check scaling progress
kubectl get pods -n todo-app -w
```

### Rolling Updates
```bash
# Update backend image
kubectl set image deployment/backend-deployment backend=todo-backend:v2 -n todo-app

# Check rollout status
kubectl rollout status deployment/backend-deployment -n todo-app

# Rollback if needed
kubectl rollout undo deployment/backend-deployment -n todo-app
```

**Explanation: Scaling and Updates**

Kubernetes makes it easy to scale applications horizontally and perform rolling updates with zero downtime. The scheduler automatically distributes new pods across available nodes.

---

## Step 10: Real-World Troubleshooting
### Common Issues We Encountered

#### Issue 1: Health Check Failures

Problem: Backend pods showing 0/2 ready with HTTP 500 errors

Symptoms:

```bash
Warning  Unhealthy  6m22s (x3 over 6m42s)  kubelet  Liveness probe failed: HTTP probe failed with statuscode: 500
```

Solution:

- MongoDB authentication conflict
- Fixed by removing authentication for demo environment
- Added detailed logging to identify the root cause

#### Issue 2: Frontend-Backend Communication

Problem: Frontend loads but can't add todos

Symptoms: 

Network requests failing, CORS errors

Solution:

- Enhanced CORS configuration
- Fixed API URL in ConfigMap
- Added request logging for debugging

#### Issue 3: Frontend Not Calling Backend API

Problem: Frontend loads but adding todos doesn't work, no requests reach backend

Symptoms:

- Frontend appears to work but nothing happens when adding todos
- No requests appear in backend logs
- Frontend logs show requests to wrong URL

Root Cause: React environment variables must be available during build time, not runtime

Solution:

- Create .env file in frontend directory with correct API URL
- Rebuild Docker image to include the configuration
- Understanding: ConfigMaps work for runtime configuration, but React compiles environment variables into static JavaScript

### Common React + Kubernetes Gotcha

```bash
# This doesn't work - ConfigMap only affects runtime
REACT_APP_API_URL: "http://localhost:30001"  # In ConfigMap

# This works - .env file affects build time
REACT_APP_API_URL=http://localhost:30001     # In .env file
```

### Debugging Workflow

```bash
# 1. Check pod status
kubectl get pods -n todo-app

# 2. Examine pod details
kubectl describe pod POD_NAME -n todo-app

# 3. Check logs
kubectl logs -f deployment/backend-deployment -n todo-app

# 4. Test connectivity
kubectl port-forward service/backend-service 8080:5000 -n todo-app

# 5. Verify configuration
kubectl get configmap todo-config -n todo-app -o yaml
```

---

## Step 10: Cleanup

```bash
# Delete all resources in the namespace
kubectl delete namespace todo-app

# Or delete individual resources
kubectl delete -f k8s/ --recursive
```

---

## Key Concepts Summary

### **Deployments**

- Manage replica sets and pods
- Provide declarative updates
- Handle rolling updates and rollbacks
- Ensure desired state is maintained

### **Services**

- **ClusterIP**: Internal communication only
- **NodePort**: External access via node IP
- **LoadBalancer**: Cloud provider load balancer
- Enable service discovery and load balancing

### **ConfigMaps**

- Store configuration data separately from application code
- Can be mounted as volumes or environment variables
- Enable configuration without rebuilding images

### **Logs**

- Aggregated from all containers
- Accessible via kubectl logs command
- Essential for debugging and monitoring

### **Docker Images**

- Containerized applications with all dependencies
- Tagged for version management
- Foundation for Kubernetes pods

---

## Challenges for Advanced Learning

1. **Add Persistent Volumes** for MongoDB data persistence
2. **Implement Ingress** for better routing
3. **Add Secrets** for sensitive data (passwords, API keys)
4. **Create Horizontal Pod Autoscaler** for automatic scaling
5. **Add Health Checks** with custom endpoints
6. **Implement Blue-Green Deployment** strategy

---

## Final Thoughts

Congratulations! You've successfully deployed a complete full-stack application using Kubernetes. You've learned how to:

- Build and manage Docker images
- Create and manage Kubernetes deployments
- Configure services for internal and external communication
- Use ConfigMaps for configuration management
- Deploy and manage databases in Kubernetes
- Monitor applications through logs
- Scale and update applications

This hands-on experience gives you a solid foundation for working with Kubernetes in production environments. The concepts you've learned today are the building blocks for more advanced Kubernetes features and patterns.

**Remember**: 

Kubernetes is a powerful platform, and mastery comes with practice. Keep experimenting, building, and deploying!

---

## Resources

- [Kubernetes Official Documentation](https://kubernetes.io/docs/)
- [Docker Desktop Kubernetes](https://docs.docker.com/desktop/kubernetes/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Best Practices for Kubernetes](https://kubernetes.io/docs/concepts/configuration/overview/)

Thank you!\
Kirk