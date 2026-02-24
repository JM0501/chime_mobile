# 📱 Chime – Secure Real-Time Chat Application

Chime is a secure, real-time chat application built using **Flutter** and powered by a **Node.js + Express + MongoDB** backend.  
It features JWT-based authentication, encrypted messaging logic, live user search, and scalable real-time communication using Socket.IO.

This mobile app was built to demonstrate full-stack engineering ability across mobile UI, backend API design, WebSocket communication, and secure authentication flows.

---

## 🚀 Features

### 🔐 **Secure Authentication**
- JWT-based login & registration  
- Encrypted password storage (bcrypt)  
- Token validation middleware  
- Secure session handling  

### 💬 **Real-Time Messaging**
- Bi-directional communication via Socket.IO  
- Instant message delivery  
- “User online/offline” presence indicators  
- Message timestamps & ordering  

### 🔎 **Live User Search**
- Fast, responsive search queries  
- Indexed MongoDB lookup for performance  
- Debounced UI interactions  

### 📱 **Clean Mobile UI (Flutter)**
- Modern chat interface  
- Smooth navigation & state management  
- Supports both light & dark themes  

---

## 🧰 Tech Stack

### **Frontend (Mobile)**
- **Flutter**
- Dart
- Provider / Riverpod (if used for state)
- Material Design UI components

### **Backend**
- **Node.js**
- Express.js
- MongoDB & Mongoose ORM
- Socket.IO (real-time communication)
- JWT (JSON Web Tokens)
- bcrypt (password hashing)

---

## 📡 Architecture Overview
Chime follows a client–server architecture:

