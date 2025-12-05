import jwt from "jsonwebtoken";

export default function authMiddleware(req, res, next){
  try {
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) return res.status(401).json({ message: "Unauthorized" });
    
    const payload = jwt.verify(token, process.env.ACCESS_TOKEN_SECRET);

    req.user = {...payload, id: payload.userId };
    next();
  } catch (error) {
    res.status(401).json({ message: "Invalid token" });
  }
};


